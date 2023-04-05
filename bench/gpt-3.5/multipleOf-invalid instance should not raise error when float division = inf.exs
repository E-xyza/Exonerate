defmodule :"multipleOf-invalid instance should not raise error when float division = inf-gpt-3.5" do
  def validate(%{"type" => "integer", "multipleOf" => multiple_of} = value) do
    if is_integer(value) and rem(value, trunc(multiple_of)) == 0 do
      :ok
    else
      :error
    end
  end

  def validate(%{"type" => "integer", "multipleOf" => _} = value) do
    if is_integer(value) do
      :ok
    else
      :error
    end
  end

  def validate(%{"type" => "object"} = value) when is_map(value) do
    :ok
  end

  def validate(_) do
    :error
  end
end
