defmodule :"format-validation of JSON pointers-gpt-3.5" do
  @doc "Validates the given decoded JSON value against the jsonschema `{\"format\": \"json-pointer\"}`.\n\nPossible returns:\n- :ok - if the given JSON value passes the validation\n- :error - otherwise\n"
  @spec validate(map) :: :ok | :error
  def validate(object) when is_map(object) do
    with {"#" <> _} <- Map.get(object, "$id") do
      :ok
    else
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end