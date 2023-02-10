defmodule Exonerate.Filter.PatternProperties do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter_from_cached(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)
    schema_pointer = JsonPointer.to_uri(pointer)

    pattern =
      name
      |> Cache.fetch!()
      |> JsonPointer.resolve!(pointer)

    raise "foo"

    Tools.maybe_dump(
      quote do
      end,
      opts
    )
  end
end
