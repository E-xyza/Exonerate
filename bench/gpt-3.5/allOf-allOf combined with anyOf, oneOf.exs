defmodule :"allOf-allOf combined with anyOf, oneOf-gpt-3.5" do
  def validate(object) when is_integer(object) do
    if is_multiple_of(object, 2) do
      :ok
    else
      :error
    end
  end

  def validate(object) when is_integer(object) do
    if is_multiple_of(object, 3) do
      :ok
    else
      :error
    end
  end

  def validate(object) when is_integer(object) do
    if is_multiple_of(object, 5) do
      :ok
    else
      :error
    end
  end

  def is_multiple_of(value, n) do
    rem(value, n) == 0
  end
end
