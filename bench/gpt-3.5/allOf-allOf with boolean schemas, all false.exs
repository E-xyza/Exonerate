defmodule :"allOf-allOf with boolean schemas, all false-gpt-3.5" do
  def validate({}) do
    :ok
  end

  def validate(%{} = object) do
    case validate_object(object) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(%{"type" => "object"}) do
    true
  end

  defp validate_object(_) do
    false
  end
end