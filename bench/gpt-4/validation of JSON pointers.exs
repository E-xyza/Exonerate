defmodule :"validation of JSON pointers" do
  def validate(json_pointer) when is_binary(json_pointer) do
    if valid_json_pointer?(json_pointer) do
      :ok
    else
      :error
    end
  end

  def validate(_), do: :error

  defp valid_json_pointer?(json_pointer) do
    # Check if json_pointer is a valid JSON pointer
    case Regex.match?(~r/^((\/([^/~]|(~[01]))*)*$/, json_pointer) do
      true -> true
      false -> false
    end
  end
end
