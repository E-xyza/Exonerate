defmodule Exonerate.Metadata do
  @moduledoc false

  @metadata_call %{
    "$id" => :id,
    "$schema" => :schema,
    "default" => :default,
    "examples" => :examples,
    "description" => :description,
    "title" => :title
  }

  @metadata_keys Map.keys(@metadata_call)

  def metadata_functions(name, schema, entrypoint) do
    case JsonPointer.resolve!(schema, entrypoint) do
      nil ->
        raise "the entrypoint #{entrypoint} does not exist in your JSONschema"

      bool when is_boolean(bool) ->
        []

      map when is_map(map) ->
        for {k, v} when k in @metadata_keys <- map do
          call = @metadata_call[k]

          quote do
            @spec unquote(name)(unquote(call)) :: String.t()
            def unquote(name)(unquote(call)) do
              unquote(v)
            end
          end
        end
    end
  end
end
