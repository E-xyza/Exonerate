defmodule :"if-then-else-if and then without else-gpt-3.5" do
  def validate(schema) do
    cond do
      is_map(schema) and schema["if"] ->
        if_clause = schema["if"]
        then_clause = schema["then"]

        if translate(if_clause) do
          translate(then_clause)
        else
          :ok
        end

      true ->
        :ok
    end
  end

  defp translate({"exclusiveMaximum", value}) do
    fn
      number when number < value -> true
      _ -> false
    end
  end

  defp translate({"minimum", value}) do
    fn
      number when number >= value -> true
      _ -> false
    end
  end

  defp translate({"type", _type}) when _type == "object" do
    fn
      object when is_map(object) -> true
      _ -> false
    end
  end

  defp translate(_) do
    :error
  end
end
