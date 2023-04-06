defmodule :"uniqueItems-uniqueItems=false with an array of items-gpt-3.5" do
  def validate(json)
      when is_map(json) and is_map(json["prefixItems"]) and length(json["prefixItems"]) == 2 do
    first_type = json["prefixItems"][0]["type"]
    second_type = json["prefixItems"][1]["type"]
    unique_items = json["uniqueItems"]

    if first_type == second_type and unique_items == false do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end