defmodule :"unevaluatedProperties-nested unevaluatedProperties, outer true, inner false, properties inside-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_fields(object) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_fields(object) do
    case object do
      %{"foo" => value} when is_binary(value) -> :ok
      _ -> :error
    end
  end
end
