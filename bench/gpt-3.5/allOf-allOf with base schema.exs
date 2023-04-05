defmodule :"allOf with base schema-gpt-3.5" do
  def validate(object) when is_map(object) do
    case validate_all_of(object) do
      :ok ->
        case Map.fetch(object, :bar) do
          {:ok, val} when is_integer(val) -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end

  defp validate_all_of(object) do
    case object do
      %{"foo" => foo} ->
        case validate_baz(null, foo) do
          :ok -> :ok
          _ -> :error
        end

      %{"baz" => nil} ->
        case validate_foo(null, nil) do
          :ok -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp validate_foo(null, nil) do
    :ok
  end

  defp validate_foo(schema, _) do
    :error
  end

  defp validate_baz(null, nil) do
    :ok
  end

  defp validate_baz(schema, _) do
    :error
  end
end