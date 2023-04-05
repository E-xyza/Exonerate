defmodule :"const with -2.0 matches integer and float types-gpt-3.5" do
  elixir

  defmodule :"const-const with -2.0 matches integer and float types" do
    def validate(schema) do
      case schema do
        %{"const" => -2.0} ->
          fn value ->
            if value == -2 or value == -2.0 do
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
end