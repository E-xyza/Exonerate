defmodule ExonerateTest.BowtieTest do
  use ExUnit.Case, async: true

  alias Exonerate.Bowtie.Runner

  describe "Runner.run/4" do
    test "validates a simple type schema" do
      schema = %{"type" => "string"}
      tests = [
        %{"description" => "valid string", "instance" => "hello"},
        %{"description" => "invalid integer", "instance" => 42}
      ]

      results = Runner.run(schema, tests, %{}, nil)

      assert [%{valid: true}, %{valid: false}] = results
    end

    test "validates with properties" do
      schema = %{
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "string"},
          "age" => %{"type" => "integer"}
        },
        "required" => ["name"]
      }

      tests = [
        %{"description" => "valid object", "instance" => %{"name" => "Alice", "age" => 30}},
        %{"description" => "missing required", "instance" => %{"age" => 30}},
        %{"description" => "wrong type", "instance" => %{"name" => 123}}
      ]

      results = Runner.run(schema, tests, %{}, nil)

      assert [%{valid: true}, %{valid: false}, %{valid: false}] = results
    end

    test "validates with draft-07 dialect" do
      schema = %{"type" => "array", "items" => %{"type" => "number"}}
      tests = [
        %{"description" => "valid array", "instance" => [1, 2, 3]},
        %{"description" => "invalid item", "instance" => [1, "two", 3]}
      ]

      results = Runner.run(schema, tests, %{}, "http://json-schema.org/draft-07/schema#")

      assert [%{valid: true}, %{valid: false}] = results
    end

    test "handles boolean schemas" do
      # true schema accepts everything
      results_true = Runner.run(true, [%{"instance" => "anything"}], %{}, nil)
      assert [%{valid: true}] = results_true

      # false schema rejects everything
      results_false = Runner.run(false, [%{"instance" => "anything"}], %{}, nil)
      assert [%{valid: false}] = results_false
    end
  end
end
