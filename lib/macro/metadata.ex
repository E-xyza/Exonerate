defmodule Exonerate.Metadata do

  @type json     :: Exonerate.json
  @type specmap  :: Exonerate.specmap
  @type defblock :: Exonerate.defblock

  @spec set_title(specmap, String.t, atom) :: [defblock]
  def set_title(spec, title, method) do
    rest = spec
    |> Map.delete("title")
    |> Exonerate.matcher(method)

    [quote do
      def unquote(method)(:title), do: unquote(title)
    end | rest]
  end

  @spec set_description(specmap, String.t, atom) :: [defblock]
  def set_description(spec, description, method) do
    rest = spec
    |> Map.delete("description")
    |> Exonerate.matcher(method)

    [quote do
      def unquote(method)(:description), do: unquote(description)
    end | rest]
  end

  @spec set_default(specmap, json, atom) :: [defblock]
  def set_default(spec, default, method) do
    rest = spec
    |> Map.delete("default")
    |> Exonerate.matcher(method)

    [quote do
      def unquote(method)(:default), do: unquote(default)
    end | rest]
  end

  @spec set_examples(specmap, [json], atom) :: [defblock]
  def set_examples(spec, examples, method) do
    rest = spec
    |> Map.delete("examples")
    |> Exonerate.matcher(method)

    [quote do
      def unquote(method)(:examples), do: unquote(examples)
    end | rest]
  end

  @spec set_schema(specmap, String.t, atom) :: [defblock]
  def set_schema(map, schema, module) do
    rest = map
    |> Map.delete("$schema")
    |> Exonerate.matcher(module)

    [quote do
       def unquote(module)(:schema), do: unquote(schema)
     end | rest]
  end

  @spec set_id(map, String.t, atom) :: [defblock]
  def set_id(map, id, module) do
    rest = map
    |> Map.delete("$id")
    |> Exonerate.matcher(module)

    [quote do
      def unquote(module)(:id), do: unquote(id)
     end | rest]
  end

end
