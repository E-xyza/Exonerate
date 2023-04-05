defmodule :"validation of relative JSON pointers-gpt-3.5" do
  def validate(%{"$ref" => pointer} = decoded_json) do
    case validate_pointer(pointer, decoded_json) do
      true -> :ok
      false -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_pointer(pointer, decoded_json) do
    {ref, path} = get_ref_and_path(pointer)

    case Map.get(decoded_json, ref) do
      nil -> false
      value -> follow_path(path, value)
    end
  end

  defp get_ref_and_path(pointer) do
    [ref | path] =
      String.split(
        pointer,
        "/"
      )

    {ref, path}
  end

  defp follow_path([], _) do
    true
  end

  defp follow_path([key | rest], map) do
    case Map.get(map, key) do
      nil -> false
      value -> follow_path(rest, value)
    end
  end
end