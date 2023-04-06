defmodule :"anyOf-nested anyOf, to check validation semantics-gpt-3.5" do
  def validate(null) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate(%{"anyOf" => [first | _]} = object) do
    case first do
      %{"anyOf" => _} -> validate(object)
      _ -> validate(first)
    end
  end

  def validate(%{"type" => "null"} = null) do
    validate(null)
  end

  def validate(%{"type" => "object"} = object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end
end