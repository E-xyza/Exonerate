defmodule Exonerate.Type.Number do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler

  alias Exonerate.Validator

  defstruct [:pointer, :schema]
  @type t :: %__MODULE__{}

  def parse(_, _), do: %__MODULE__{}

  @impl true
  @spec compile(t, Validator.t) :: Macro.t
  def compile(_, validator) do
    quote do
      def unquote(Validator.to_fun(validator))(number, path) when is_number(number) do
        :ok
      end
    end
  end
end
