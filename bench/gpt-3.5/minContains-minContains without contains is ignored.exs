defmodule :"minContains without contains is ignored-gpt-3.5" do
  def validate(schema) do
    case schema do
      %{"minContains" => 1} ->
        quote do
          def validate(list) when is_list(list) and length(filter(& &1), &1) >= 1 do
            :ok
          end

          def validate(_) do
            :error
          end
        end
        |> Macro.to_module()

      _ ->
        :error
    end
  end
end