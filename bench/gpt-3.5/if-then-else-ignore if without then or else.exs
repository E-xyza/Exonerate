defmodule :"ignore if without then or else-gpt-3.5" do
  @spec validate(String.t()) :: :ok | :error
  def validate(json) do
    {:ok, decoded} = Jason.decode(json)

    case decoded do
      %{"if" => %{"const" => 0}} ->
        :ok

      %{"type" => "object"} ->
        (fn
           object when is_map(object) -> :ok
           _ -> :error
         end).()

      _ ->
        :error
    end
  end
end
