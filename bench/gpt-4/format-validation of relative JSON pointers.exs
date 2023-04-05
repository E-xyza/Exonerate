defmodule :"format-validation of relative JSON pointers" do
  def validate(relative_json_pointer) when is_binary(relative_json_pointer) do
    if valid_relative_json_pointer?(relative_json_pointer) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp valid_relative_json_pointer?(relative_json_pointer) do
    # Check if relative_json_pointer is a valid relative JSON pointer
    case Regex.match?(~r/^([0-9]+)(#[^#]*|((\/([^/~]|(~[01]))*)*))$/, relative_json_pointer) do
      true -> true
      false -> false
    end
  end
end
