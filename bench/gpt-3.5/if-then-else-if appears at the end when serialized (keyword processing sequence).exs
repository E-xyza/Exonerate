defmodule :"if-then-else-if appears at the end when serialized (keyword processing sequence)-gpt-3.5" do
  def validate(%{} = object) do
    case validate_object(object) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_object(object) do
    case object do
      %{
        "else" => %{"const" => "other"},
        "if" => %{"maxLength" => 4},
        "then" => %{"const" => "yes"}
      } ->
        :ok

      map ->
        validate_map(map)

      _ ->
        :error
    end
  end

  defp validate_map(%{"type" => "object"} = map) do
    :ok
  end

  defp validate_map(_) do
    :error
  end

  defp validate_array([]) do
    :ok
  end

  defp validate_array(_) do
    :error
  end

  defp validate_string("") do
    :ok
  end

  defp validate_string(_) do
    :error
  end

  defp validate_number(_) do
    :ok
  end

  defp validate_bool(_) do
    :ok
  end

  defp validate_null(nil) do
    :ok
  end

  defp validate_null(_) do
    :error
  end
end