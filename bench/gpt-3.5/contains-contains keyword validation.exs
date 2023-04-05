defmodule :"contains keyword validation-gpt-3.5" do
  def validate(object)
      when is_map(object) and tuple_size(:maps.find(object, "contains", :error)) == 2 do
    {key, value} =
      :maps.find(
        object,
        "contains"
      )

    if is_list(value) and length(value) >= get_minimum(key) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end

  defp get_minimum(key) do
    minimum = tuple_size(:maps.find(key, "minimum", :error))

    if minimum == 2 do
      :maps.get(key, "minimum", :error)
    else
      0
    end
  end
end