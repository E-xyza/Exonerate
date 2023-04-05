defmodule :"oneOf-oneOf-gpt-3.5" do
  def validate(value) do
    case value do
      <<_::size(0)>> -> :error
      %{"type" => "integer"} -> :ok
      %{"minimum" => min} when is_integer(min) and min < 2 -> :error
      _ -> :ok
    end
  end
end
