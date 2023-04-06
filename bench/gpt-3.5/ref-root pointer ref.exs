defmodule :"ref-root pointer ref-gpt-3.5" do
  def validate(object) when is_map(object) do
    case Map.keys(object) do
      ["foo"] -> validate(Map.get!(object, "foo"))
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end
