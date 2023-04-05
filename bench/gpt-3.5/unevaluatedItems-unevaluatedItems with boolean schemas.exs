defmodule :"unevaluatedItems with boolean schemas-gpt-3.5" do
  def validate(value) do
    case value do
      [] -> :ok
      _x when is_list(value) -> :error
      %{__struct__: "MapSet"} -> :ok
      _x when is_map(value) -> :error
      _ -> :ok
    end
  end
end
