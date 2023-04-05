defmodule :"patternProperties with boolean schemas" do
  def validate(object) when is_map(object) do
    # Iterate over each key-value pair in the object
    for {key, value} <- object do
      case Regex.match?(~r/^b/, key) do
        true ->
          # If the key matches the pattern 'b.*', it should have a boolean value of false
          case value do
            false -> :ok
            _ -> :error
          end
        false ->
          # If the key matches the pattern 'f.*', it should have a boolean value of true
          case value do
            true -> :ok
            _ -> :error
          end
      end
    end

    # If all keys have been validated successfully, return :ok
    :ok
  end

  def validate(_), do: :error
end
