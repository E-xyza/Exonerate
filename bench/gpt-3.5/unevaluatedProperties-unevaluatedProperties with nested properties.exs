defmodule :"unevaluatedProperties with nested properties-gpt-3.5" do
  def validate(object) when is_map(object) do
    props = [:foo, :bar]
    nested_props = [:nested]

    case(
      Map.has_key?(object, :foo) and Map.get(object, :foo) |> is_binary,
      Map.has_key?(
        object,
        :bar
      ) and
        Map.get(
          object,
          :bar
        )
        |> is_binary,
      Map.has_key?(
        object,
        :unevaluated
      ) and
        Map.get(
          object,
          :unevaluated
        )
        |> validate_nested_properties()
    ) do
      {true, true, :ok} -> :ok
      _, _, error -> error
    end
  end

  def validate(_) do
    :error
  end

  def validate_nested_properties(object) when is_map(object) do
    props = [:baz]

    case Map.has_key?(object, :baz) and Map.get(object, :baz) |> is_binary do
      true -> :ok
      _ -> :error
    end
  end

  def validate_nested_properties(_) do
    :ok
  end
end