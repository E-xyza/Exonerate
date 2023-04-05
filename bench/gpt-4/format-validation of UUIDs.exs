defmodule :"validation of UUIDs" do
  def validate(uuid) when is_binary(uuid) do
    if valid_uuid?(uuid) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp valid_uuid?(uuid) do
    # Check if uuid is a valid UUID
    uuid_pattern = ~r/\A(?:[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000)\z/u

    case Regex.match?(uuid_pattern, uuid) do
      true -> true
      false -> false
    end
  end
end
