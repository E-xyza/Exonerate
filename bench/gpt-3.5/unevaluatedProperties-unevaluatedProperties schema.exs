defmodule :"unevaluatedProperties-unevaluatedProperties schema-gpt-3.5" do
  def validate(json) do
    case json do
      %{} = object -> :ok
      %{_ => string} when is_binary(string) and byte_size(string) >= 3 -> :ok
      _ -> :error
    end
  end
end
