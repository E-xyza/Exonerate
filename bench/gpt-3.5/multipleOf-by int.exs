defmodule :"multipleOf-by int-gpt-3.5" do
  def validate({:array, items: {:number, multipleOf: 2}} = value) when is_list(value) do
    :ok
  end

  def validate(_) do
    :error
  end
end
