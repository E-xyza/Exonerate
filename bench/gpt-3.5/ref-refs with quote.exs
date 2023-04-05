defmodule :"refs with quote-gpt-3.5" do
  def validate(%{} = object) do
    :ok
  end

  def validate(_) do
    :error
  end

  @schema %{
    "$defs" => %{"foo\"bar" => %{"type" => "number"}},
    "properties" => %{"foo\"bar" => %{"$ref" => "#/$defs/foo%22bar"}}
  }
  defp validate_ref_ref(%{"$ref" => ref}) do
    validate_ref(ref)
  end

  defp validate_ref_ref(_) do
    :ok
  end

  defp validate_ref(ref) do
    ["#", path] =
      String.split(
        ref,
        "/",
        parts: 2
      )

    [head | tail] =
      String.split(
        path,
        "/"
      )

    case head do
      "$defs" ->
        {:ok, definition} = Map.fetch_in(@schema, [head, to_atom(head) |> to_binary, tail])
        validate_ref(definition)

      _ ->
        :error
    end
  end

  defp to_binary(string) do
    string |> String.replace("\\", "\\\\") |> String.replace("\"", "\\\"") |> String.to_binary()
  end
end