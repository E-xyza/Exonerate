defmodule :"unevaluatedItems with $ref-gpt-3.5" do
  def validate(object) when is_map(object) do
    case object do
      %{
        "$defs" => _,
        "$ref" => "#/$defs/bar",
        "prefixItems" => [true, %{"type" => "string"}] | [_],
        "type" => "array",
        "unevaluatedItems" => false
      } ->
        :ok

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end
end