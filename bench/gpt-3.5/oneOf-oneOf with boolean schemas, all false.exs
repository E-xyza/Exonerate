defmodule :"oneOf-oneOf with boolean schemas, all false-gpt-3.5" do
  def validate(object) when is_binary(object) do
    case Jason.decode(object) do
      {:ok, parsed} -> validate(parsed)
      _ -> {:error, "Invalid JSON"}
    end
  end

  def validate(object) when is_map(object) do
    case object["oneOf"] do
      [false, false, false] -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end
