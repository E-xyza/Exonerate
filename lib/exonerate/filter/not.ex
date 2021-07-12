defmodule Exonerate.Filter.Not do
  @moduledoc false

  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  defstruct [:context, :schema]

  alias Exonerate.Validator

  @impl true
  def parse(validator = %Validator{}, %{"not" => _}) do

    schema = Validator.parse(
      validator.schema,
      ["not" | validator.pointer],
      authority: validator.authority)

    module = %__MODULE__{context: validator, schema: schema}

    %{validator |
      children: [module | validator.children],
      distribute: [module | validator.distribute]}
  end

  def distribute(filter, value_ast, path_ast) do
    quote do
      negated = try do
        unquote(fun(filter, "not"))(unquote(value_ast), unquote(path_ast))
      catch
        error = {:error, list} when is_list(list) -> error
      end
      case negated do
        :ok ->
          Exonerate.mismatch(unquote(value_ast), unquote(path_ast), guard: "not")
        {:error, list} ->
          :ok
      end
    end
  end

  @impl true
  def compile(filter = %__MODULE__{}) do
    [Validator.compile(filter.schema)]
  end

  defp fun(filter, what) do
    filter.context
    |> Validator.jump_into(what)
    |> Validator.to_fun
  end
end
