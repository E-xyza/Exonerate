defmodule :"maximum validation-gpt-3.5" do
  def validate(object) when is_map(object) do
    cond do
      Map.has_key?(object, "maximum") and is_number(Map.get(object, "maximum")) and
          Map.get(object, "maximum") <= 3.0 ->
        :ok

      true ->
        :error
    end
  end

  def validate(_) do
    :error
  end
end