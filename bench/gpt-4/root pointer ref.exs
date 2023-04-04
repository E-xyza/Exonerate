defmodule :"root pointer ref" do
  def validate(map) when is_map(map) do
    case Map.keys(map) do
      [:foo] ->
        validate(map[:foo])

      [] ->
        :ok

      _ ->
        :error
    end
  end

  def validate(_), do: :error
end
