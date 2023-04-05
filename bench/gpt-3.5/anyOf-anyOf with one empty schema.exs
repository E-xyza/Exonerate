defmodule :"anyOf-anyOf with one empty schema-gpt-3.5" do
  def validate(data) do
    case data do
      %{} -> :ok
      n when is_integer(n) or is_float(n) -> :ok
      _ -> :error
    end
  end
end
