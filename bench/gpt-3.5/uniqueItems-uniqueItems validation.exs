defmodule :"uniqueItems validation-gpt-3.5" do
  def validate(object) when is_list(object) and Enum.uniq(object) == object do
    :ok
  end

  def validate(_) do
    :error
  end
end