defmodule Exonerate.Type.String do

  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler

  defstruct []
  @type t :: %__MODULE__{}

  alias Exonerate.Type
  alias Exonerate.Validator

  @impl true
  @spec parse(Type.json) :: t
  def parse(_schema) do
    %__MODULE__{}
  end

  @impl true
  @spec compile(t, Validator.t) :: Macro.t
  def compile(_, validator) do
    quote do
      def unquote(Validator.to_fun(validator))(string, path) when is_binary(string) do
        if String.valid?(string) do
          :ok
        else
          Exonerate.mismatch(string, path)
        end
      end
    end
  end

end
