defmodule :"allOf with two empty schemas-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate(%{"allOf" => [schema1, schema2]}) do
    case {validate(schema1), validate(schema2)} do
      {:ok, :ok} -> :ok
      _ -> :error
    end
  end
end