defmodule :"unevaluatedItems-unevaluatedItems with items-gpt-3.5" do
  def validate({:array, items, prefix_items, unevaluated_items})
      when is_boolean(items) and is_list(prefix_items) and is_boolean(unevaluated_items) do
    if items do
      case prefix_items do
        [string: _], [] -> :ok
        _ -> :error
      end
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end
