defmodule :"additionalProperties-additionalProperties can exist by itself-gpt-3.5" do
  def validate(%{"additionalProperties" => %{"type" => "boolean"}} = data) do
    case data do
      %{"additionalProperties" => _} = object -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end