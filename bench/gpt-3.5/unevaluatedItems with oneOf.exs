defmodule :"unevaluatedItems with oneOf-gpt-3.5" do
  def validate(json) do
    case json do
      [] -> :ok
      [first | rest] when is_valid_element(first) -> validate(rest)
      _ -> :error
    end
  end

  defp is_valid_element(element) do
    case element do
      %{"prefixItems" => [true, const]} when is_valid_const(const) ->
        true

      %{
        "type" => "array",
        "unevaluatedItems" => false,
        "prefixItems" => [%{"const" => "foo"}],
        "oneOf" => one_of
      } ->
        Enum.all?(one_of, fn x -> is_valid_one_of(x) end)

      _ ->
        false
    end
  end

  defp is_valid_const(const) do
    const == "bar" or const == "baz"
  end

  defp is_valid_one_of(one_of) do
    one_of == [true, %{"const" => "bar"}] or one_of == [true, %{"const" => "baz"}]
  end
end
