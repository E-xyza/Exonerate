defmodule :"if appears at the end when serialized (keyword processing sequence)" do
  def validate(value) when is_binary(value) do
    case String.length(value) do
      len when len <= 4 ->
        if value == "yes", do: :ok, else: :error

      _ ->
        if value == "other", do: :ok, else: :error
    end
  end

  def validate(_), do: :error
end
