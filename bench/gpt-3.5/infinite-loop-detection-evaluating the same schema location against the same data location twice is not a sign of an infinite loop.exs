defmodule :"infinite-loop-detection-evaluating the same schema location against the same data location twice is not a sign of an infinite loop-gpt-3.5" do
  def validate(map) when is_map(map) do
    if Map.has_key?(map, "foo") do
      with %{"foo" => _foo} <- Map.take(map, ["foo"]),
           _ <-
             Map.drop(
               map,
               ["foo"]
             ),
           _ <- Enum.map(Map.values(map), &validate_int(&1)) do
        :ok
      else
        _ -> :error
      end
    else
      case Enum.all?(Map.values(map), &validate_int/1) do
        true -> :ok
        false -> :error
      end
    end
  end

  def validate(_) do
    :error
  end

  defp validate_int(value) do
    case value do
      x when is_integer(x) -> :ok
      _ -> :error
    end
  end
end
