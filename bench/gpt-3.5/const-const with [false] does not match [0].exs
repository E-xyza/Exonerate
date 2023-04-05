defmodule :"const-const with [false] does not match [0]-gpt-3.5" do
  defmodule Validation do
    def validate(false) do
      :ok
    end

    def validate(_) do
      :error
    end
  end

  def validate(json) do
    case json do
      %{"const" => [false]} -> Validation.validate(false)
      %{"type" => "object"} when is_map(json) -> :ok
      %{"type" => "number"} when is_number(json) -> :ok
      %{"type" => "string"} when is_binary(json) or is_list(json) -> :ok
      %{"type" => "array"} when is_list(json) -> :ok
      %{"type" => "boolean"} when json in [true, false] -> :ok
      _ -> :error
    end
  end
end
