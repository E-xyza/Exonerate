defmodule :"validation of regexes" do
  
defmodule Jsonschema do
  def validate(json) when is_map(json) and Map.has_key?(json, "format") do
    case json["format"] do
      "regex" -> fn(value) when is_binary(value) and String.match?(value, //) -> :ok
      _ -> :error
    end.().()
  end

  def validate(_), do: :ok
end

end
