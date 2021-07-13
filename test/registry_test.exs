defmodule ExonerateTest.RegistryTest do
  use ExUnit.Case, async: true

  alias Exonerate.Registry

  test "you can register a fun and then request it back" do
    assert :ok == Registry.register(%{}, [], :foo)
    assert :foo == Registry.request(%{}, [])
  end

  test "registering a function does not affect a different schema" do
    assert :ok == Registry.register(%{}, [], :foo)
    refute :foo == Registry.request(%{"foo" => "bar"}, [])
  end

  test "registering a function does not affect a different pointer" do
    assert :ok == Registry.register(%{}, [], :foo)
    refute :foo == Registry.request(%{}, ["bar"])
  end

  test "if you try to register a fun more than once, you get a cached result" do
    assert :ok == Registry.register(%{}, [], :foo)
    assert {:exists, :foo} == Registry.register(%{}, [], :bar)
    assert {:exists, :foo} == Registry.register(%{}, [], :bar)
  end

  test "if you make a request that doesn't exist, you get a consistent reference that can be resolved on registration" do
    registry_ref = Registry.request(%{}, [])
    assert ^registry_ref = Registry.request(%{}, [])
    assert {:needed, ^registry_ref} = Registry.register(%{}, [], :foo)
  end

  test "if you make a request that doesn't exist and you don't register it, you can pull it with the needed function" do
    registry_ref = Registry.request(%{}, [])
    assert [%{authority: authority, pointer: []}] = Registry.needed(%{})
    assert String.starts_with?("#{registry_ref}", authority)
    assert [] = Registry.needed(%{"nonexistent" => 1})
  end

  test "if you have already satisfied the request then you don't need it anymore." do
    registry_ref = Registry.request(%{}, [])
    assert {:needed, ^registry_ref} = Registry.register(%{}, [], :foo)
    assert [] = Registry.needed(%{})
  end
end
