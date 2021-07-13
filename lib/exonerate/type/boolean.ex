defmodule Exonerate.Type.Boolean do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  defstruct [:context, filters: []]
  @type t :: %__MODULE__{}

  alias Exonerate.Validator

  @impl true
  @spec parse(Validator.t, Type.json) :: t
  def parse(validator, _schema) do
    %__MODULE__{context: validator}
  end

  @impl true
  @spec compile(t) :: Macro.t
  def compile(artifact) do
    combining = Validator.combining(artifact.context, quote do object end, quote do path end)
    quote do
      defp unquote(Validator.to_fun(artifact.context))(boolean, path) when is_boolean(boolean) do
        unquote_splicing(combining)
      end
    end
  end
end
