defmodule Exonerate.Filter.Const do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}
  defstruct [:context, :const]

  alias Exonerate.Type
  alias Exonerate.Context

  import Context, only: [fun: 2]

  @impl true
  def parse(validation = %Context{}, %{"const" => const}) do
    type = %{Type.of(const) => nil}

    %{
      validation
      | types: Type.intersection(validation.types, type),
        guards: [%__MODULE__{context: validation, const: const}]
    }
  end

  def compile(filter = %__MODULE__{}) do
    quote do
      defp unquote(fun(filter, []))(value, path)
           when value != unquote(Macro.escape(filter.const)) do
        Exonerate.mismatch(value, path, guard: "const")
      end
    end
  end
end
