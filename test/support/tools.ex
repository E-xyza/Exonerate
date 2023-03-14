defmodule ExonerateTest.Tools do
  def find_first_defp(defp = {:defp, _, _}), do: defp

  def find_first_defp(list) when is_list(list) do
    Enum.find_value(list, &find_first_defp/1)
  end

  def find_first_defp({:__block__, _, block}) do
    find_first_defp(block)
  end

  def find_first_defp(etc) do
    nil
  end
end
