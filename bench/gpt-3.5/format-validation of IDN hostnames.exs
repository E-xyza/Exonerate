defmodule :"format-validation of IDN hostnames-gpt-3.5" do
  def validate(object) when is_map(object) and validate_idn_hostname(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp validate_idn_hostname(object) do
    case Map.fetch(object, "format") do
      {:ok, "idn-hostname"} ->
        case Map.keys(object) do
          ["format"] -> true
          _ -> false
        end

      _ ->
        false
    end
  end
end