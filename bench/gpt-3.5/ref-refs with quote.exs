defmodule :"ref-refs with quote-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_properties(object, %{"foo\"bar" => fn val -> is_number(val) end}) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_properties(object, properties) do
    Enum.all?(properties, fn {prop_key, prop_fun} ->
      case get_in(object, String.split(prop_key, "\""), :invalid) do
        :invalid -> false
        val -> prop_fun.(val)
      end
    end)
  end
end
