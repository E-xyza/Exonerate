defmodule :"unevaluatedItems with anyOf-gpt-3.5" do
  def validate(object) when is_list(object) do
    case object do
      [{"foo" | tail}] -> any_of_validate(tail)
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp any_of_validate([]) do
    :ok
  end

  defp any_of_validate([h | tail]) do
    case h do
      true ->
        case tail do
          [{"bar" | _}] -> :ok
          _ -> any_of_validate(tail)
        end

      [true, true, {"baz" | _}] ->
        :ok

      _ ->
        any_of_validate(tail)
    end
  end
end