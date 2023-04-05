defmodule :"format-validation of UUIDs-gpt-3.5" do
  def validate(object)
      when is_map(object) and Map.has_key?(object, "format") and object["format"] == "uuid" do
    :ok
  end

  def validate(_) do
    :error
  end
end
