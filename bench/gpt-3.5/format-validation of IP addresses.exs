defmodule :"format-validation of IP addresses-gpt-3.5" do
  def validate(value) do
    case value do
      %{"format" => "ipv4"} -> :ok
      _ -> :error
    end
  end
end