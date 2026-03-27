defmodule Exonerate.Formats.Punycode do
  @moduledoc """
  Minimal Punycode implementation for IDN hostname validation.
  Based on RFC 3492: https://www.rfc-editor.org/rfc/rfc3492

  This implementation provides encode/decode functions sufficient for
  validating internationalized domain names without requiring the
  full :idna library.
  """

  # Punycode constants from RFC 3492
  @base 36
  @tmin 1
  @tmax 26
  @skew 38
  @damp 700
  @initial_bias 72
  @initial_n 128
  @delimiter ?-

  @doc """
  Decode a punycode string to a unicode charlist.

  Raises ArgumentError if the punycode is invalid or decodes to
  characters that are not valid for domain names (control characters,
  code points above Unicode range, etc.).

  ## Examples

      iex> Exonerate.Formats.Punycode.decode(~c"bcher-kva")
      ~c"bücher"

      iex> Exonerate.Formats.Punycode.decode(~c"Mnchen-3ya")
      ~c"München"
  """
  @spec decode(charlist()) :: charlist()
  def decode(input) when is_list(input) do
    # Split on the last delimiter
    {basic, extended} = split_on_delimiter(input)

    # Initialize state
    n = @initial_n
    bias = @initial_bias
    i = 0

    # Process extended portion
    {output, _n, _bias, _i} = decode_extended(extended, basic, n, bias, i)

    # Validate output - reject control characters and invalid code points
    validate_output!(output)

    output
  end

  # Validate decoded characters are valid for hostnames
  # Rejects control characters (U+0000-U+001F, U+007F-U+009F) and
  # code points above the Unicode range
  defp validate_output!(chars) do
    Enum.each(chars, fn c ->
      cond do
        # Control characters C0 (U+0000-U+001F)
        c >= 0x00 and c <= 0x1F ->
          raise ArgumentError, "invalid character in punycode: control character U+#{Integer.to_string(c, 16) |> String.pad_leading(4, "0")}"

        # DEL (U+007F)
        c == 0x7F ->
          raise ArgumentError, "invalid character in punycode: control character U+007F"

        # Control characters C1 (U+0080-U+009F)
        c >= 0x80 and c <= 0x9F ->
          raise ArgumentError, "invalid character in punycode: control character U+#{Integer.to_string(c, 16) |> String.pad_leading(4, "0")}"

        # Code points above Unicode range
        c > 0x10FFFF ->
          raise ArgumentError, "invalid punycode: code point out of Unicode range"

        # Valid
        true ->
          :ok
      end
    end)
  end

  defp split_on_delimiter(input) do
    case :lists.reverse(input) do
      reversed ->
        case Enum.split_while(reversed, fn c -> c != @delimiter end) do
          {after_delim, []} ->
            # No delimiter found
            {[], :lists.reverse(after_delim)}

          {after_delim_rev, [@delimiter | before_delim]} ->
            {:lists.reverse(before_delim), :lists.reverse(after_delim_rev)}
        end
    end
  end

  defp decode_extended([], output, n, bias, i), do: {output, n, bias, i}

  defp decode_extended(input, output, n, bias, i) do
    out_len = length(output)

    {delta, remaining} = decode_delta(input, 0, 1, @base, bias)

    new_i = i + delta
    new_n = n + div(new_i, out_len + 1)
    new_i = rem(new_i, out_len + 1)

    # Insert character at position new_i
    new_output = insert_at(output, new_i, new_n)

    new_bias = adapt(delta, out_len + 1, n == @initial_n)

    decode_extended(remaining, new_output, new_n, new_bias, new_i + 1)
  end

  defp decode_delta([], delta, _w, _k, _bias), do: {delta, []}

  defp decode_delta([c | rest], delta, w, k, bias) do
    digit = decode_digit(c)
    new_delta = delta + digit * w

    t = threshold(k, bias)

    if digit < t do
      {new_delta, rest}
    else
      new_w = w * (@base - t)
      decode_delta(rest, new_delta, new_w, k + @base, bias)
    end
  end

  defp decode_digit(c) when c >= ?a and c <= ?z, do: c - ?a
  defp decode_digit(c) when c >= ?A and c <= ?Z, do: c - ?A
  defp decode_digit(c) when c >= ?0 and c <= ?9, do: c - ?0 + 26

  defp threshold(k, bias) do
    cond do
      k <= bias + @tmin -> @tmin
      k >= bias + @tmax -> @tmax
      true -> k - bias
    end
  end

  defp adapt(delta, numpoints, first_time) do
    delta =
      if first_time do
        div(delta, @damp)
      else
        div(delta, 2)
      end

    delta = delta + div(delta, numpoints)

    adapt_loop(delta, 0)
  end

  defp adapt_loop(delta, k) when delta > div((@base - @tmin) * @tmax, 2) do
    adapt_loop(div(delta, @base - @tmin), k + @base)
  end

  defp adapt_loop(delta, k) do
    k + div((@base - @tmin + 1) * delta, delta + @skew)
  end

  defp insert_at(list, index, value) do
    {before, after_part} = Enum.split(list, index)
    before ++ [value | after_part]
  end

  @doc """
  Encode a unicode charlist to punycode.

  ## Examples

      iex> Exonerate.Formats.Punycode.encode(~c"bücher")
      ~c"bcher-kva"

      iex> Exonerate.Formats.Punycode.encode(~c"München")
      ~c"Mnchen-3ya"
  """
  @spec encode(charlist()) :: charlist()
  def encode(input) when is_list(input) do
    # Separate basic (ASCII) and non-basic characters
    basic = Enum.filter(input, fn c -> c < 128 end)
    non_basic = input |> Enum.filter(fn c -> c >= 128 end) |> Enum.sort() |> Enum.uniq()

    if non_basic == [] do
      basic
    else
      # Initialize state
      n = @initial_n
      delta = 0
      bias = @initial_bias
      h = length(basic)
      b = h

      # Build output starting with basic characters
      output =
        if b > 0 do
          basic ++ [@delimiter]
        else
          []
        end

      {encoded, _n, _delta, _bias, _h} = encode_extended(input, non_basic, output, n, delta, bias, h)
      encoded
    end
  end

  defp encode_extended(_input, [], output, n, delta, bias, h), do: {output, n, delta, bias, h}

  defp encode_extended(input, [m | rest_non_basic], output, n, delta, bias, h) do

    # Calculate delta increment
    delta = delta + (m - n) * (h + 1)
    n = m

    # Process each character in input
    {output, delta, bias, h} =
      Enum.reduce(input, {output, delta, bias, h}, fn c, {out, d, b, h_acc} ->
        cond do
          c < n ->
            {out, d + 1, b, h_acc}

          c == n ->
            # Encode delta
            {encoded_delta, new_bias} = encode_delta(d, b, out)
            {encoded_delta, 0, new_bias, h_acc + 1}

          true ->
            {out, d, b, h_acc}
        end
      end)

    encode_extended(input, rest_non_basic, output, n + 1, delta + 1, bias, h)
  end

  defp encode_delta(delta, bias, output) do
    {encoded, remaining, _k} = encode_delta_loop(delta, bias, [], @base)
    {output ++ encoded ++ [encode_digit(remaining)], adapt(delta, length(output) + 1, false)}
  end

  defp encode_delta_loop(q, bias, acc, k) do
    t = threshold(k, bias)

    if q < t do
      {acc, q, k}
    else
      digit = rem(q - t, @base - t) + t
      new_q = div(q - t, @base - t)
      encode_delta_loop(new_q, bias, acc ++ [encode_digit(digit)], k + @base)
    end
  end

  defp encode_digit(d) when d < 26, do: d + ?a
  defp encode_digit(d), do: d - 26 + ?0
end
