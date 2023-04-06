defmodule :"oneOf-oneOf with required-gpt-3.5" do
  def validate(object) when is_map(object) do
    case object do
      %{"foo" => _, "bar" => _} -> :ok
      %{"foo" => _, "baz" => _} -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end