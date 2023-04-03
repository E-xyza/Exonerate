defmodule ExonerateTest.Custom do
  def generate!(_), do: %{"foo" => %{"bar" => %{"type" => "string"}}}
end

defmodule ExonerateTest.DecoderTest do
  use ExUnit.Case, async: true
  require Exonerate

  Exonerate.function_from_string(
    :defp,
    :yaml,
    """
    foo:
      bar:
        type: string
    """,
    entrypoint: "/foo/bar",
    decoder: YamlElixir
  )

  test "yaml" do
    assert :ok = yaml("bar")
    assert {:error, _} = yaml(42)
  end

  Exonerate.function_from_string(
    :defp,
    :jason_explicit,
    """
    {"foo": {"bar": {"type": "string"}}}
    """,
    entrypoint: "/foo/bar",
    decoder: Jason
  )

  test "jason_explicit" do
    assert :ok = jason_explicit("bar")
    assert {:error, _} = jason_explicit(42)
  end

  Exonerate.function_from_string(
    :defp,
    :poison,
    """
    {"foo": {"bar": {"type": "string"}}}
    """,
    entrypoint: "/foo/bar",
    decoder: {Poison, :decode!}
  )

  test "poison" do
    assert :ok = poison("bar")
    assert {:error, _} = poison(42)
  end

  alias ExonerateTest.Custom
  # note we can't embed this because the next function
  # has a strict compile-time execution dependency.

  Exonerate.function_from_string(
    :defp,
    :custom,
    """
    nonsense
    """,
    entrypoint: "/foo/bar",
    # note this is an alias!
    decoder: {Custom, :generate!}
  )

  test "custom" do
    assert :ok = custom("bar")
    assert {:error, _} = custom(42)
  end
end
