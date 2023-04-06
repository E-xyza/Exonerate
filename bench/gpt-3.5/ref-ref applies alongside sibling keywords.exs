defmodule :"ref-ref applies alongside sibling keywords-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate(%{"$defs" => defs, "properties" => props} = schema) do
    check_refs(defs) and check_props(props) and :ok
  end

  def validate(_) do
    :error
  end

  def check_refs(%{"reffed" => %{"type" => "array"}}) do
    true
  end

  def check_refs(_) do
    false
  end

  def check_props(props) do
    case props["foo"] do
      %{"$ref" => "#/$defs/reffed", "maxItems" => 2} -> true
      _ -> false
    end
  end
end