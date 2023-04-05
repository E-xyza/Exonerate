defmodule :"required with empty array-gpt-3.5" do
  def validate(object) when is_map(object) do
    props = Map.keys(object)

    case props -- [] do
      [] -> :ok
      missing_props -> {:error, "Required properties missing: #{inspect(missing_props)}"}
    end
  end

  def validate(_) do
    {:error, "Invalid object type"}
  end
end