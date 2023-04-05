defmodule :"ref-escaped pointer ref" do
  def validate(map) when is_map(map) do
    keys = Map.keys(map)

    percent_valid? =
      cond do
        :percent in keys ->
          is_integer(Map.get(map, :percent))

        true ->
          true
      end

    slash_valid? =
      cond do
        :slash in keys ->
          is_integer(Map.get(map, :slash))

        true ->
          true
      end

    tilde_valid? =
      cond do
        :tilde in keys ->
          is_integer(Map.get(map, :tilde))

        true ->
          true
      end

    if percent_valid? and slash_valid? and tilde_valid? do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error
end
