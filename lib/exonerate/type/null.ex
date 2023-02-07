defmodule Exonerate.Type.Null do
  @moduledoc false

  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  defstruct [:context, filters: []]
  @type t :: %__MODULE__{}

  alias Exonerate.Context

  @impl true
  @spec parse(Context.t(), Type.json()) :: t
  def parse(context, _schema) do
    %__MODULE__{context: context}
  end

  @impl true
  @spec compile(t) :: Macro.t()
  def compile(filter) do
    combining =
      Context.combining(
        filter.context,
        quote do
          null
        end,
        quote do
          path
        end
      )

    quote do
      defp unquote(Context.fun(filter))(null, path) when is_nil(null) do
        (unquote_splicing(combining))
      end
    end
  end
end
