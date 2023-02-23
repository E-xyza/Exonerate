defmodule Exonerate.Draft do
  @all_drafts ~w(4 5 6 7 2019-09 2020-12)
  def before?("4", "5"), do: true
  def before?(x, "6") when x in ~w(4 5), do: true
  def before?(x, "7") when x in ~w(4 5 6), do: true
  def before?(x, "2019-09") when x in ~w(4 5 6 7), do: true
  def before?(x, "2020-12") when x in ~w(4 5 6 7 2019-09), do: true
  def before?(x, y) when x in @all_drafts and y in @all_drafts, do: false
end
