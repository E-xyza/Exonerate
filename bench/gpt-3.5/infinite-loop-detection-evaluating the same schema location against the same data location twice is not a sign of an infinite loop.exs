defmodule :"infinite-loop-detection-evaluating the same schema location against the same data location twice is not a sign of an infinite loop-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.has_key?(object, "foo") do
      true ->
        case Map.get(object, "foo") do
          val when is_integer(val) -> :ok
          _ -> :error
        end

      false ->
        :ok
    end
  end

  def validate(_) do
    :error
  end
end