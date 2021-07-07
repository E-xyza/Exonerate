defmodule Exonerate.Type.String do
  @behaviour Exonerate.Type

  alias Exonerate.Validator

  @impl true
  @spec compile(Validator.t) :: Macro.t
  def compile(validator) do
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
