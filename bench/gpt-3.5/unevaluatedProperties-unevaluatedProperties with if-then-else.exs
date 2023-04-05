defmodule :"unevaluatedProperties-unevaluatedProperties with if-then-else-gpt-3.5" do
  def validate(object) when is_map(object) do
    if Map.has_key?(object, "foo") do
      if object["foo"] == "then" do
        if Map.has_key?(object, "bar") do
          :ok
        else
          :error
        end
      else
        :error
      end
    else
      if Map.has_key?(object, "baz") do
        :ok
      else
        :error
      end
    end
  end

  def validate(_) do
    :error
  end
end
