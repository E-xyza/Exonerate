defmodule :"not multiple types-gpt-3.5" do
  def validate(object) when is_map(object) or is_list(object) do
    do_validate(object)
  end

  def validate(_) do
    :error
  end

  defp do_validate(object) do
    case object do
      x when is_integer(x) or is_boolean(x) -> :error
      x when is_map(x) -> do_validate_map(x)
      x when is_list(x) -> do_validate_list(x)
      _ -> :ok
    end
  end

  defp do_validate_map(map) do
    for {_key, value} <- map do
      case do_validate(value) do
        :error -> return(:error)
        _ -> :ok
      end
    end

    :ok
  end

  defp do_validate_list(list) do
    for value <- list do
      case do_validate(value) do
        :error -> return(:error)
        _ -> :ok
      end
    end

    :ok
  end
end