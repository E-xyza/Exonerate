defmodule :"multipleOf-by number-gpt-3.5" do
  @schema %{"multipleOf" => 1.5}
  def validate(map) when is_map(map) do
    with {:ok, _} <- Jason.Validator.validate(@schema, %{root: map}),
         {:ok, _} <- check_type(map) do
      :ok
    else
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp check_type(map) do
    case @schema["type"] do
      "object" -> {:ok, is_map(map)}
      "integer" -> {:ok, is_integer(map)}
      "number" -> {:ok, is_number(map)}
      "string" -> {:ok, is_binary(map)}
      "array" -> {:ok, is_list(map)}
      _ -> {:error, :unsupported_type}
    end
  end
end
