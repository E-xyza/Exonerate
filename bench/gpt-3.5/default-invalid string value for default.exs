defmodule :"invalid string value for default-gpt-3.5" do
  def validate(object) when is_map(object) do
    if Map.has_key?(object, "bar") do
      bar_value =
        Map.get(
          object,
          "bar"
        )

      if is_binary(bar_value) and byte_size(bar_value) >= 4 do
        :ok
      else
        :error
      end
    else
      :ok
    end
  end

  def validate(_) do
    :error
  end
end