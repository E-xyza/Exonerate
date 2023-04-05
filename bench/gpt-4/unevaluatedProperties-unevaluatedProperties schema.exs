defmodule :"unevaluatedProperties schema" do
  def validate(object) when is_map(object) do
    unevaluated_properties_valid? =
      Enum.all?(object, fn {_, value} ->
        is_binary(value) and String.length(value) >= 3
      end)

    if unevaluated_properties_valid? do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error
end
