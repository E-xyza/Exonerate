defmodule Exonerate.Filter.MinProperties do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler

  alias Exonerate.Validator
  defstruct [:context, :count]

  def parse(artifact, %{"minProperties" => count}) do
    %{artifact |
      filters: [%__MODULE__{context: artifact.context, count: count} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{count: count}) do
    {[quote do
      defp unquote(fun(filter))(object, path) when is_map(object) and :erlang.map_size(object) < unquote(count) do
        Exonerate.mismatch(object, path, guard: unquote("minProperties"))
      end
    end], []}
  end

  defp fun(filter_or_artifact = %_{}) do
    Validator.to_fun(filter_or_artifact.context)
  end
end
