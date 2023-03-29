defmodule :"const with {\"a\": false} does not match {\"a\": 0}-gpt-3.5" do
  def validate(json) do
    case json do
      %{const: %{a: false}} ->
        :ok

      %{type: "object"} ->
        fn
          object when is_map(object) -> :ok
          _ -> :error
        end

      %{type: "string"} ->
        fn
          string when is_binary(string) -> :ok
          _ -> :error
        end

      %{type: "integer"} ->
        fn
          integer when is_integer(integer) -> :ok
          _ -> :error
        end

      %{type: "number"} ->
        fn
          number when is_number(number) -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end
end
