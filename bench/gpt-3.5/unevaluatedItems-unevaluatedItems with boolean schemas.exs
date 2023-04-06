defmodule :"unevaluatedItems-unevaluatedItems with boolean schemas-gpt-3.5" do
  def validate(value) do
    case value do
      [] ->
        :ok

      list when is_list(list) ->
        if unvalidated_items?(list) do
          :error
        else
          :ok
        end

      _ ->
        :error
    end
  end

  defp unvalidated_items?([]) do
    false
  end

  defp unvalidated_items?([_ | tail]) do
    unvalidated_items?(tail)
  end

  defp unvalidated_items?([_ | _]) do
    true
  end
end