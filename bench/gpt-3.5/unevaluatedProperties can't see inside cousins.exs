defmodule :"unevaluatedProperties can't see inside cousins" do
  
defmodule JsonSchema do
  def validate(object) when is_map(object) do
    # validate "type": "object"
    case Map.is_map(object) do
      true -> :ok
      false -> :error
    end
  end

  def validate([head | tail]) when is_list(tail) do
    # validate "allOf"
    case validate(head) do
      :ok -> validate(tail)
      _:error -> :error
    end
  end

  def validate([{"properties", properties}]) when is_map(properties) do
    # validate "properties"
    case Enum.all?(Map.keys(properties), &Map.has_key?(%{}, &1)) do
      true -> :ok
      false -> :error
    end
  end

  def validate([{"unevaluatedProperties", false}]) do
    # validate "unevaluatedProperties"
    :ok
  end

  def validate(_), do: :error
end

end
