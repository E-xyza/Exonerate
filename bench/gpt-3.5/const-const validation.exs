defmodule :"const-const validation-gpt-3.5" do
  def validate(json) do
    case json do
      %{"const" => value} when value == 2 ->
        :ok

      %{"type" => "object"} ->
        (fn
           %{} = object -> :ok
           _ -> :error
         end).()

      _ ->
        :error
    end
  end
end
