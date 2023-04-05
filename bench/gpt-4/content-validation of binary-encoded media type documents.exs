defmodule :"content-validation of binary-encoded media type documents" do
  def validate(%{"contentEncoding" => "base64", "contentMediaType" => "application/json"} = object) do
    case Jason.decode!(Base.decode64!(object)) do
      %{"type" => "object"} = json ->
        case validate_object(json) do
          true -> :ok
          false -> :error
        end
      _ ->
        :error
    end
  end

  def validate(_), do: :error

  defp validate_object(%{"type" => "object"}), do: true
  defp validate_object(_), do: false
end
