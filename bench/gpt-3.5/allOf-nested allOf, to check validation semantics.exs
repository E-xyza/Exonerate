defmodule :"nested allOf, to check validation semantics-gpt-3.5" do
  def validate(nil) do
    :ok
  end

  def validate(map = %{allOf: all_of}) do
    case Enum.all?(all_of, &(validate(map) === :ok)) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end
