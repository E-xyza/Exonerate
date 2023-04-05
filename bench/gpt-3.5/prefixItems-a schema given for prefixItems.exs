defmodule :"a schema given for prefixItems-gpt-3.5" do
  def validate(decoded_json) when is_map(decoded_json) do
    case decoded_json["prefixItems"] do
      [{%{"type" => "integer"}, _} | _] -> :ok
      [{_, {%{"type" => "string"}, _}} | _] -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end