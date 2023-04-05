defmodule :"format-validation of IP addresses-gpt-3.5" do
  def validate(%{"format" => "ipv4"} = value) when is_map(value) do
    :ok
  end

  def validate(_) do
    :error
  end
end
