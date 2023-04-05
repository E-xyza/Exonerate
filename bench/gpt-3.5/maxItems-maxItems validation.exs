defmodule :"maxItems-maxItems validation-gpt-3.5" do
  def validate(schema) do
    case schema do
      %{"maxItems" => max_items} ->
        fun = fn array ->
          case length(array) <= max_items do
            true -> :ok
            false -> :error
          end
        end

        {:function, fun}

      %{"type" => "object"} ->
        def validate(object) when is_map(object) do
          :ok
        end

        def validate(_) do
          :error
        end

        :ok

      _ ->
        :error
    end
  end
end
