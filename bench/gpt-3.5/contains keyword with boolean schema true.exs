defmodule :"contains keyword with boolean schema true-gpt-3.5" do
  def validate(object)
      when is_map(object) and Map.has_key?(object, "contains") and object["contains"] == true do
    :ok
  end

  def validate(_) do
    :error
  end
end
