defmodule Exonerate.Draft do
  @all_drafts ~w(4 5 6 7 2019-09 2020-12)

  @spec opts_before?(String.t(), keyword) :: boolean
  def opts_before?(date, opts) do
    opts
    |> Keyword.get(:draft, "2020-12")
    |> do_before?(date)
  end

  defp do_before?("4", "5"), do: true
  defp do_before?(x, "6") when x in ~w(4 5), do: true
  defp do_before?(x, "7") when x in ~w(4 5 6), do: true
  defp do_before?(x, "2019-09") when x in ~w(4 5 6 7), do: true
  defp do_before?(x, "2020-12") when x in ~w(4 5 6 7 2019-09), do: true
  defp do_before?(x, y) when x in @all_drafts and y in @all_drafts, do: false
end
