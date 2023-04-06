defmodule :"enum-heterogeneous enum-with-null validation-gpt-3.5" do
  def validate(value) do
    case value do
      6, nil -> :ok
      _ -> :error
    end
  end
end