defmodule :"not more complex schema-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    if Map.has_key?(object, "foo") do
      :error
    else
      :ok
    end
  end
end