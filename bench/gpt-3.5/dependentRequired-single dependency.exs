defmodule :"dependentRequired-single dependency-gpt-3.5" do
  def validate(object) when is_map(object) do
    required_fields = Map.get(object, "bar", [])

    for field <- required_fields, Map.get(object, field) == nil do
      return(:error)
    end

    :ok
  end

  def validate(_) do
    :error
  end
end