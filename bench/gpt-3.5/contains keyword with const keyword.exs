defmodule :"contains keyword with const keyword-gpt-3.5" do
  def validate(schema) do
    case schema do
      %{"contains" => %{"const" => value}} ->
        fn
          x when x == value -> :ok
          x -> {:error, "Value #{inspect(x)} does not match #{inspect(value)}"}
        end

      %{"type" => "object"} ->
        fn
          x when is_map(x) -> :ok
          _ -> :error
        end

      _ ->
        fn _ -> :error end
    end
  end
end
