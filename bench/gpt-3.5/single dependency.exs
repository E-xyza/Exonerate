defmodule :"single dependency-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_bar(object) do
      :ok -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_bar(object) when is_map(object) do
    case Map.has_key?(object, "bar") do
      true ->
        case validate_foo(Map.get(object, "bar")) do
          :ok -> :ok
          _ -> :error
        end

      false ->
        :ok
    end
  end

  defp validate_foo(object) when is_map(object) do
    Map.has_key?(object, "foo")
  end

  defp validate_foo(_) do
    false
  end
end
