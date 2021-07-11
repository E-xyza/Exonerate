defmodule Exonerate.Filter.MinItems do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :count]

  def parse(artifact, %{"minItems" => count}) do
    check_key = fun0(artifact, "minItems")

    %{artifact |
      needs_enum: true,
      post_enum_pipeline: [{check_key, []} | artifact.post_enum_pipeline],
      enum_init: Map.put(artifact.enum_init, :index, 0),
      filters: [%__MODULE__{context: artifact.context, count: count} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{count: count}) do
    {[], [
      quote do
        defp unquote(fun0(filter, "minItems"))(acc, path) do
          if acc.index < unquote(count) do
            Exonerate.mismatch(acc.array, path)
          end
          acc
        end
      end
    ]}
  end

  defp fun0(filter_or_artifact = %_{}, what) do
    filter_or_artifact.context
    |> Validator.jump_into(what)
    |> Validator.to_fun
  end
end
