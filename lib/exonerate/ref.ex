defmodule Exonerate.Ref do
  @moduledoc false

  alias Exonerate.Registry

  defstruct [:pointer, :authority, :target]
  @type t :: %__MODULE__{
    pointer: JsonPointer.t,
    target: atom
  }

  def from_uri("#", %{pointer: pointer, schema: schema, authority: authority}) do
    %__MODULE__{pointer: pointer, authority: authority, target: Registry.request(schema, [])}
  end

  def from_uri("#" <> uri, %{pointer: pointer, schema: schema, authority: authority}) do
    target = Registry.request(schema, JsonPointer.from_uri(uri))
    %__MODULE__{pointer: pointer, authority: authority, target: target}
  end
end
