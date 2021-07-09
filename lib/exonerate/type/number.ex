defmodule Exonerate.Type.Number do
  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler

  defstruct []
  @type t :: %__MODULE__{}

  def parse(_), do: %__MODULE__{}

  @impl true
  @spec compile(Validator.t) :: Macro.t
  def compile(validator) do
    quote do
      def unquote(Validator.to_fun(validator))(number, path) when is_number(number) do
        :ok
      end
    end
  end
end
