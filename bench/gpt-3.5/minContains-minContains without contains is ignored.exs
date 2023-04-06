defmodule :"minContains-minContains without contains is ignored-gpt-3.5" do
  def validate(x) when is_list(x) do
    validate_list(x, 0)
  end

  def validate(_) do
    :error
  end

  defp validate_list([], n) when n >= 1 do
    :ok
  end

  defp validate_list([], _) do
    :error
  end

  defp validate_list([x | xs], n) do
    case validate(x) do
      :ok -> validate_list(xs, n + 1)
      _ -> validate_list(xs, n)
    end
  end
end