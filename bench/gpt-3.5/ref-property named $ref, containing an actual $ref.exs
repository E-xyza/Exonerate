defmodule :"property named $ref, containing an actual $ref-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    {:error, "Object is not a valid JSON."}
  end

  def validate(value) when is_binary(value) do
    {:error, "String value is not a valid JSON."}
  end

  def validate(_) do
    {:error, "Unknown JSON value."}
  end
end
