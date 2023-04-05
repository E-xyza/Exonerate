defmodule :"pattern validation-gpt-3.5" do
  def validate(object) when is_map(object) and is_match?(object, "a*") do
    :ok
  end

  def validate(_) do
    :error
  end

  defp is_match?(object, pattern) do
    regex = regex_from_pattern(pattern)

    case object do
      %{"$regex" => custom_regex} -> regex_match?(custom_regex, regex)
      :binary -> regex_match?(object, regex)
      _ -> false
    end
  end

  defp regex_from_pattern(pattern) do
    pattern
    |> Regex.escape()
    |> Regex.replace("^", "\\A")
    |> Regex.replace("$", "\\z")
    |> Regex.replace("*", ".+")
    |> Regex.compile()
  end

  defp regex_match?(input, regex) do
    case Regex.match?(regex, input) do
      true -> true
      false -> false
      nil -> false
    end
  end
end