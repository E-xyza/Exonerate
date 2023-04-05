defmodule :"validation of JSON pointers-gpt-3.5" do
  def validate(%{"$ref" => _} = object) do
    validate_ref(object)
  end

  def validate(%{"format" => "json-pointer"} = object) do
    validate_json_pointer(object)
  end

  def validate(_) do
    :error
  end

  defp validate_ref(%{"$ref" => ref} = object) do
    {schema_module, pointer} = resolve_reference(ref)
    schema = schema_module.validate(pointer)
    schema.validate(object)
  end

  defp validate_ref(_) do
    :error
  end

  defp validate_json_pointer(%{"$data" => data} = object) do
    try do
      {:ok, _} =
        Jason.decode!(data,
          keys: :atoms
        )

      :ok
    rescue
      _ -> :error
    end
  end

  defp validate_json_pointer(_) do
    :error
  end

  defp resolve_reference(reference) do
    {module_name, pointer} =
      URI.parse(reference).fragment |> URI.decode_www_form() |> List.first()

    {Code.require_file(module_name), pointer}
  end
end