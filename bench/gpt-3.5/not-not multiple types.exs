defmodule :"not multiple types-gpt-3.5" do
  def validate(json) do
    case json do
      %{} = object -> :ok
      integer when is_integer(integer) -> {:error, "Expected non-integer value"}
      true, false -> {:error, "Expected non-boolean value"}
      _ -> {:error, "Schema validation failed"}
    end
  end
end
