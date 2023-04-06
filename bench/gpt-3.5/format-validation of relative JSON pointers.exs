defmodule :"format-validation of relative JSON pointers-gpt-3.5" do
  def validate(pointer) when is_binary(pointer) and is_relative_json_pointer(pointer) do
    :ok
  end

  def validate(_) do
    :error
  end

  defp is_relative_json_pointer(pointer) do
    case String.split(pointer, "/") do
      ["", _ | _] -> true
      _ -> false
    end
  end
end