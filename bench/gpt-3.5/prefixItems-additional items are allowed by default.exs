defmodule :"additional items are allowed by default-gpt-3.5" do
  def validate(%{"prefixItems" => [%{"type" => "integer"}]}) do
    :ok
  end

  def validate(_) do
    :error
  end
end