defmodule :"anyOf with boolean schemas, all true-gpt-3.5" do
  def validate(object) when object in [true, false] do
    :ok
  end

  def validate(object) when is_list(object) do
    case object do
      [true, true] -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end
