defmodule :"validation of binary string-encoding-gpt-3.5" do
  def validate(%{"contentEncoding" => "base64"} = object) do
    case is_binary(object["value"]) do
      true -> :ok
      false -> :error
    end
  end

  def validate(%{"contentEncoding" => other} = _object) do
    Logger.error("Unknown content encoding: #{other}")
    :error
  end

  def validate(%{"type" => "object"} = object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end
