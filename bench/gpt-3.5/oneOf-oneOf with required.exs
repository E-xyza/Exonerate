defmodule :"oneOf-oneOf with required-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_object(object)
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case object do
      %{"foo" => foo, "bar" => bar} -> :ok
      %{"foo" => foo, "baz" => baz} -> :ok
      _ -> :error
    end
  end
end
