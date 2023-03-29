defmodule :"items with boolean schema (true)-gpt-3.5" do
  @doc "Validates a decoded JSON value against a predefined JSON schema.\n"
  def validate(%{"items" => true} = object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end
