defmodule :"oneOf with required-gpt-3.5" do
  def validate(object) when is_map(object) and is_valid_object(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  def is_valid_object(object) do
    case object do
      %{"foo" => _, "bar" => _} -> true
      %{"foo" => _, "baz" => _} -> true
      _ -> false
    end
  end
end