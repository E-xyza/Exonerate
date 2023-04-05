defmodule :"validation of binary string-encoding-gpt-3.5" do
  def validate(object) when is_map(object) and object["contentEncoding"] == "base64" do
    :ok
  end

  def validate(_) do
    :error
  end
end