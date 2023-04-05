defmodule :"pattern-pattern is not anchored" do
  
def validate(json) do
  case json do
    %{"pattern" => pattern} ->
      regex = ~r/#{pattern}/
      fn(value) when is_binary(value) and regex === value -> :ok
      _ -> :error
    %{"type" => "object"} ->
      fn(map) when is_map(map) -> :ok
      _ -> :error
    _ -> :error
  end
end

end
