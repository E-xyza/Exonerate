defmodule :"invalid string value for default-gpt-3.5" do
  def validate(obj) when is_map(obj) do
    case Map.has_key?(obj, "bar") do
      false ->
        :error

      true ->
        bar_val =
          Map.get(
            obj,
            "bar"
          )

        if is_binary(bar_val) and String.length(bar_val) >= 4 do
          :ok
        else
          :error
        end
    end
  end

  def validate(_) do
    :error
  end
end
