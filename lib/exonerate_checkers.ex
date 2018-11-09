defmodule Exonerate.Checkers do
  @moduledoc """
    contains a series of functions that are used to aid in validation of
    JSONSchema maps.
  """

  def check_additionalitems(arr, item_fun, additionalitem_fun) when is_list(arr) do
    ((arr |> Enum.slice(length(item_fun)..-1) |> Enum.map(additionalitem_fun)) ++
       (arr |> Enum.zip(item_fun) |> Enum.map(fn {x, f} -> f.(x) end)))
    |> Exonerate.error_reduction()
  end

  def check_maxproperties(val, p) do
    if val |> Map.keys() |> length > p,
      do: {:error, "#{Jason.encode! val} does not conform to JSON schema"},
      else: :ok
  end

  def check_minproperties(val, p) do
    if val |> Map.keys() |> length < p,
      do: {:error, "#{Jason.encode! val} does not conform to JSON schema"},
      else: :ok
  end

  def check_minlength(val, l) do
    if String.length(val) < l,
      do: {:error, "#{Jason.encode! val} does not conform to JSON schema"},
      else: :ok
  end

  def check_maxlength(val, l) do
    if String.length(val) > l,
      do: {:error, "#{Jason.encode! val} does not conform to JSON schema"},
      else: :ok
  end

  def check_regex(re, val) do
    if Regex.match?(re, val),
      do: :ok,
      else: {:error, "#{Jason.encode! val} does not conform to JSON schema"}
  end

  #for now, pass all checking functions.
  def check_format_datetime(str), do: :ok
  def check_format_email(str), do: :ok
  def check_format_hostname(str), do: :ok
  def check_format_ipv4(str), do: :ok
  def check_format_ipv6(str), do: :ok
  def check_format_uri(str), do: :ok

  def check_unique([]), do: :ok
  def check_unique([singleton]), do: :ok
  def check_unique([head | tail]), do: check_unique(tail, tail, head)
  def check_unique([head | tail], [], _), do: check_unique(tail)
  def check_unique(_, [ref | tail], ref), do: {:error, "array contains duplicate values"}
  def check_unique(x, [head | tail], ref), do: check_unique(x, tail, ref)
end
