defmodule :"oneOf-oneOf complex types-gpt-3.5" do
  def validate(object) when is_map(object) do
    case object do
      %{"bar" => bar} when is_integer(bar) -> :ok
      %{"foo" => foo} when is_binary(foo) -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end