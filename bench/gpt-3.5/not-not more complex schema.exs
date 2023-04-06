defmodule :"not-not more complex schema-gpt-3.5" do
  @spec validate(decoded_json_value) :: :ok | :error
  def validate(json) do
    case json do
      %{"foo" => _} -> :error
      %{} -> :ok
      _ -> :ok
    end
  end
end