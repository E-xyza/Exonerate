defmodule Exonerate.Filter.Enum do
  @moduledoc false
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Type
  alias Exonerate.Type.{Array, Boolean, Integer, Null, Number, Object, String}
  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :enums]

  @impl true
  def parse(validation = %Validator{}, %{"enum" => enums}) do
    types = Map.new(enums, &{Type.of(&1), nil})

    %{
      validation
      | types: Type.intersection(validation.types, types),
        guards: [%__MODULE__{context: validation, enums: enums} | clean(validation.guards)]
    }
  end

  defp clean(guards) do
    Enum.reject(guards, &(&1.__struct__ == Exonerate.Filter.Type))
  end

  def compile(%__MODULE__{context: context, enums: enums}) do
    context_types = Map.keys(context.types)

    literals =
      enums
      |> Enum.filter(fn enum ->
        Enum.any?(context_types, &to_guard(&1).(enum))
      end)
      |> Enum.map(&Macro.escape/1)

    # erlang OTP < 24 compiler flaw.
    if true in literals do
      quote do
        defp unquote(fun(context, []))(value, path)
             when value not in unquote(Enum.reject(literals, &(&1 === true))) and value != true do
          Exonerate.mismatch(value, path, guard: "enum")
        end
      end
    else
      quote do
        defp unquote(fun(context, []))(value, path)
             when value not in unquote(literals) do
          Exonerate.mismatch(value, path, guard: "enum")
        end
      end
    end
  end

  defp to_guard(Array), do: &is_list/1
  defp to_guard(Boolean), do: &is_boolean/1
  defp to_guard(Integer), do: &is_integer/1
  defp to_guard(Null), do: &is_nil/1
  defp to_guard(Number), do: &is_float/1
  defp to_guard(Object), do: &is_map/1
  defp to_guard(String), do: &is_binary/1
end
