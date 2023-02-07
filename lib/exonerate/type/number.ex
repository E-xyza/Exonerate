defmodule Exonerate.Type.Number do
  @moduledoc false

  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Context

  import Context, only: [fun: 2]

  defstruct [:context, filters: []]
  @type t :: %__MODULE__{}

  @context_filters ~w(minimum maximum exclusiveMinimum exclusiveMaximum multipleOf)
  @context_modules Map.new(@context_filters, &{&1, Filter.from_string(&1)})

  @impl true
  @spec parse(Context.t(), Type.json()) :: t
  # draft <= 7 refs inhibit type-based analysis
  def parse(context = %{draft: draft}, %{"$ref" => _}) when draft in ~w(4 6 7) do
    %__MODULE__{context: context}
  end

  def parse(context, schema) do
    %__MODULE__{context: context}
    |> Tools.collect(@context_filters, fn
      filter, filter when is_map_key(schema, filter) ->
        Filter.parse(filter, @context_modules[filter], schema)

      filter, _ ->
        filter
    end)
  end

  @impl true
  @spec compile(t) :: Macro.t()
  def compile(filter) do
    combining =
      Context.combining(
        filter.context,
        quote do
          number
        end,
        quote do
          path
        end
      )

    quote do
      defp unquote(fun(filter, []))(number, path) when is_number(number) do
        (unquote_splicing(combining))
      end
    end
  end
end
