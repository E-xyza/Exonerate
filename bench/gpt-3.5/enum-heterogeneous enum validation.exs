defmodule :"enum-heterogeneous enum validation-gpt-3.5" do
  def validate(data) when is_integer(data) and data in [6] do
    :ok
  end

  def validate(data) when is_binary(data) and data == "foo" do
    :ok
  end

  def validate(data) when is_list(data) and data == [] do
    :ok
  end

  def validate(data) when is_boolean(data) and data == true do
    :ok
  end

  def validate(data) when is_map(data) and data == %{"foo" => 12} do
    :ok
  end

  def validate(_) do
    :error
  end
end