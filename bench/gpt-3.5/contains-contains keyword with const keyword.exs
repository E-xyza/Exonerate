defmodule :"contains-contains keyword with const keyword-gpt-3.5" do
  def validate(object) when is_map(object) do
    contains_const_5(object)
  end

  def validate(_) do
    :error
  end

  defp contains_const_5(object) do
    case contains?(object, 5) do
      true -> :ok
      false -> :error
    end
  end

  defp contains?(object, value) do
    case object do
      %{"contains" => %{"const" => const_value}} ->
        const_value == value

      %{"contains" => contains} ->
        case contains do
          [object | _tail] when is_list(contains) -> contains?(object, value)
          object -> contains?(object, value)
        end

      _ ->
        false
    end
  end
end