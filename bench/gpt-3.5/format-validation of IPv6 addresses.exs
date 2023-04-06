defmodule :"format-validation of IPv6 addresses-gpt-3.5" do
  def validate(object) when is_map(object) and is_ipv6(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp is_ipv6(object) do
    case Map.get(object, "format") do
      "ipv6" -> true
      _ -> false
    end
  end
end