defmodule :"invalid type for default-gpt-3.5" do
  @doc "Validates a decoded JSON value against the given schema.\n\n:param value: the decoded JSON value to validate\n:returns: :ok if the value is valid according to the schema,\n          or an error tuple otherwise\n"
  def validate(value) do
    case value do
      %{"foo" => _} when is_integer(Map.get(value, "foo")) -> :ok
      _ -> {:error, "Value does not match schema"}
    end
  end
end
