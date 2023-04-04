defmodule :"uniqueItems=false with an array of items and additionalItems=false-gpt-3.5" do
  def validate(dec_json)
      when is_map(dec_json) or (is_list(dec_json) and is_boolean(List.first(dec_json))) do
    :ok
  end

  def validate(_) do
    :error
  end
end
