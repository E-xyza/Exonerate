defmodule :"type as array with one item-gpt-3.5" do
  def validate(json) do
    case json do
      %{"type" => "string"} when is_binary(json) -> :ok
      %{"type" => ["string"]} when is_binary(json) -> :ok
      %{"type" => "object"} when is_map(json) -> :ok
      %{"type" => ["object"]} when is_map(json) -> :ok
      _ -> :error
    end
  end
end
