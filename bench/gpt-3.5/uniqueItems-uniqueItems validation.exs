defmodule :"uniqueItems validation-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate(%{"uniqueItems" => true, "items" => items}) when is_list(items) do
    if Enum.uniq(items) == items do
      :ok
    else
      :error
    end
  end
end
