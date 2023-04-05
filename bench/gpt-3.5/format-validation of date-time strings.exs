defmodule :"validation of date-time strings-gpt-3.5" do
  def validate(value) do
    case value do
      _ when is_binary(value) ->
        case DateTime.from_iso8601(value) do
          {:ok, _} -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end
end
