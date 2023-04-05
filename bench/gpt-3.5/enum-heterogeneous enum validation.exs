defmodule :"heterogeneous enum validation-gpt-3.5" do
  def validate(enum) when is_integer(enum) and enum == 6 do
    :ok
  end

  def validate(enum) when is_binary(enum) and enum == "foo" do
    :ok
  end

  def validate(enum) when is_list(enum) and length(enum) == 0 do
    :ok
  end

  def validate(enum) when is_boolean(enum) and enum == true do
    :ok
  end

  def validate(enum) when is_map(enum) and Map.get(enum, "foo") == 12 do
    :ok
  end

  def validate(_) do
    :error
  end
end