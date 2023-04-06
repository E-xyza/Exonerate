defmodule :"oneOf-oneOf with missing optional property-gpt-3.5" do
  def validate(object) when is_map(object) do
    case object do
      %{"bar" => _} -> :ok
      %{"foo" => _} -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end