defmodule :"unevaluatedProperties with dependentSchemas-gpt-3.5" do
  def validate(%{"type" => "object"} = object) do
    case is_map(object) do
      true -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end