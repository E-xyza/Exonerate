defmodule Exonerate.Filter do
  @moduledoc false

  alias Exonerate.Type
  alias Exonerate.Validator

  # to be filled with a more comprensive list later.
  @type t :: module
  @type artifact :: %{__struct__: t}

  @callback parse(Validator.t | Type.artifact, Type.json) :: Validator.t | Type.artifact

  def from_string(filter), do: String.to_atom("Elixir.Exonerate.Filter.#{capitalize(filter)}")

  @spec parse(Validator.t, Filter.t) :: Validator.t
  def parse(validation, module), do: parse(validation, module, Validator.traverse(validation))

  @spec parse(Validator.t, Filter.t, Type.json) :: Validator.t
  @spec parse(Type.artifact, Filter.t, Type.json) :: Type.artifact
  def parse(validator_or_artifact, module, json), do: module.parse(validator_or_artifact, json)

  defp capitalize(<<first::binary-size(1), rest::binary>>) do
    String.capitalize(first) <> rest
  end
end
