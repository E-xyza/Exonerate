defmodule :"maxContains without contains is ignored-gpt-3.5" do
  def validate(object) when is_list(object) do
    case Enum.count(object) <= 1 do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end
end