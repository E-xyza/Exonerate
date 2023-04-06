defmodule :"unevaluatedItems-unevaluatedItems with anyOf-gpt-3.5" do
  def validate(data) when is_list(data) do
    case data do
      [{"foo"} | tail] ->
        case tail do
          [true | rest] -> validate_any_of(rest)
          _ -> :error
        end

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_any_of(data) do
    case data do
      [{"bar"} | _] -> :ok
      [true, {"baz"} | _] -> :ok
      [_ | rest] -> validate_any_of(rest)
      _ -> :error
    end
  end
end