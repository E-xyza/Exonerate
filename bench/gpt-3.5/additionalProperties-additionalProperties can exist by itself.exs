defmodule :"additionalProperties can exist by itself-gpt-3.5" do
  def validate({"additionalProperties", %{"type" => "boolean"}} = object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end
