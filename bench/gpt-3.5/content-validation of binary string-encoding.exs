defmodule :"content-validation of binary string-encoding-gpt-3.5" do
  def validate(%{"contentEncoding" => "base64"} = _) do
    :ok
  end

  def validate(_) do
    :error
  end
end