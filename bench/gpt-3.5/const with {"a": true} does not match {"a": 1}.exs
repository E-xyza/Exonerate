defmodule :"const with {\"a\": true} does not match {\"a\": 1}-gpt-3.5" do
  def validate(object) when is_map(object) do
    validate_const(object)
  end

  def validate(_) do
    :error
  end

  defp validate_const(object) do
    case object do
      %{"a" => true} -> :ok
      _ -> :error
    end
  end
end
