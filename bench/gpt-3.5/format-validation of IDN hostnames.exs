defmodule :"validation of IDN hostnames-gpt-3.5" do
  def validate(value) when is_map(value) do
    case Map.fetch(value, "format") do
      {:ok, "idn-hostname"} -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end
