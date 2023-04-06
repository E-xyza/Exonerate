defmodule :"exclusiveMaximum-exclusiveMaximum validation-gpt-3.5" do
  def validate(schema_result) do
    case schema_result do
      %{exclusiveMaximum: max} ->
        fn value ->
          if is_number(value) and value < max do
            :ok
          else
            :error
          end
        end

      _ ->
        fn _ -> :error end
    end
  end
end