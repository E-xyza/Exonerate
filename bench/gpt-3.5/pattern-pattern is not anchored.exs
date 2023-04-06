defmodule :"pattern-pattern is not anchored-gpt-3.5" do
  
defmodule :"pattern-pattern is not anchored" do
  @jsonschema %{
    "pattern": "a+"
  }

  def validate(object) when is_map(object) andmatch?(@jsonschema, object), do: :ok
  def validate(_), do: :error
end

end
