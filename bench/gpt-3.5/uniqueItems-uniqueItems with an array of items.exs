defmodule :"uniqueItems-uniqueItems with an array of items-gpt-3.5" do
  def validate(object)
      when is_map(object) and
             Map.get(
               object,
               "prefixItems"
             ) == [%{"type" => "boolean"}, %{"type" => "boolean"}] and
             Map.get(
               object,
               "uniqueItems"
             ) == true do
    :ok
  end

  def validate(_) do
    :error
  end
end