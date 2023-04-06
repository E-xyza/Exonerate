defmodule :"uniqueItems-uniqueItems validation-gpt-3.5" do
  def validate(object) when is_list(object) do
    if Enum.uniq(object) == object do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end