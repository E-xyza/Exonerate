defmodule :"enum-heterogeneous enum validation-gpt-3.5" do
  def validate(json) do
    case json do
      %{__value__: 6} -> :ok
      %{__value__: "foo"} -> :ok
      %{__value__: []} -> :ok
      %{__value__: true} -> :ok
      %{foo: 12} -> :ok
      _ -> :error
    end
  end
end
