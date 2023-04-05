defmodule :"contains keyword with boolean schema false-gpt-3.5" do
  def validate(json) do
    case json do
      %{"contains" => false} ->
        def validate(input) when not Enum.member?(input, true) do
          :ok
        end

        def validate(_) do
          :error
        end

      %{"type" => "object"} ->
        def validate(input) when is_map(input) do
          :ok
        end

        def validate(_) do
          :error
        end

      %{"type" => "array"} ->
        def validate(input) when is_list(input) do
          :ok
        end

        def validate(_) do
          :error
        end

      %{"type" => "string"} ->
        def validate(input) when is_binary(input) do
          :ok
        end

        def validate(_) do
          :error
        end

      %{"type" => "number"} ->
        def validate(input) when is_number(input) do
          :ok
        end

        def validate(_) do
          :error
        end

      %{"type" => "boolean"} ->
        def validate(true) do
          :ok
        end

        def validate(false) do
          :ok
        end

        def validate(_) do
          :error
        end

      _ ->
        def validate(_) do
          :error
        end
    end
    |> validate.(json)
  end
end
