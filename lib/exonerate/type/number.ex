defmodule Exonerate.Type.Number do
  @behaviour Exonerate.Type

  alias Exonerate.Validator

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
