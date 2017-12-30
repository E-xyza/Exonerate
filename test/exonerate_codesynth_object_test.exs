defmodule ExonerateCodesynthObjectTest do
  use ExUnit.Case, async: true
  import ExonerateTest.Helper

  @tag :exonerate_codesynth
  test "object with no restrictions" do
    codesynth_match(%{"type" => "object"}, """
      def validate_test(val) when is_map(val), do: :ok
      def validate_test(val), do: {:error, \"\#{inspect(val)} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "object with properties specifications" do
    codesynth_match(
      %{"type" => "object", "properties" => %{"test1" => %{"type" => "string"}}},
      """
        def validate_test_test1(val) when is_binary(val), do: :ok
        def validate_test_test1(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test(val) when is_map(val), do: validate_test_test1(val["test1"])
        def validate_test(val), do: {:error, \"\#{inspect(val)} does not conform to JSON schema\"}
      """
    )
  end

  @tag :exonerate_codesynth
  test "object with multiple properties specifications" do
    codesynth_match(
      %{
        "type" => "object",
        "properties" => %{"test1" => %{"type" => "string"}, "test2" => %{"type" => "integer"}}
      },
      """
        def validate_test_test1(val) when is_binary(val), do: :ok
        def validate_test_test1(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test_test2(val) when is_integer(val), do: :ok
        def validate_test_test2(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test__each({k, v}) do
          qmatch =
           case k do
             "test1" -> validate_test_test1(v)
             "test2" -> validate_test_test2(v)
             _ -> :ok
           end
        end

        def validate_test(val) when is_map(val), do: Enum.map(val, &__MODULE__.validate_test__each/1) |> Exonerate.error_reduction
        def validate_test(val), do: {:error, \"\#{inspect(val)} does not conform to JSON schema\"}
      """
    )
  end

  @tag :exonerate_codesynth
  test "object with no additional properties" do
    codesynth_match(
      %{
        "type" => "object",
        "properties" => %{"test1" => %{"type" => "string"}},
        "additionalProperties" => false
      },
      """
        def validate_test_test1(val) when is_binary(val), do: :ok
        def validate_test_test1(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test__each({k, v}) do
          qmatch = case k do
            "test1" -> {validate_test_test1(v), true}
            _ -> {:ok, false}
          end

          {result, matched} = qmatch
          if matched, do: result, else: {:error, \"does not conform to JSON schema\"}
        end

        def validate_test(val) when is_map(val), do: Enum.map(val, &__MODULE__.validate_test__each/1) |> Exonerate.error_reduction
        def validate_test(val), do: {:error, \"\#{inspect(val)} does not conform to JSON schema\"}
      """
    )
  end

  @tag :exonerate_codesynth
  test "object with additional properties with a schema" do
    codesynth_match(
      %{
        "type" => "object",
        "properties" => %{"test1" => %{"type" => "string"}},
        "additionalProperties" => %{"type" => "integer"}
      },
      """
        def validate_test__additionalProperties(val) when is_integer(val), do: :ok
        def validate_test__additionalProperties(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test_test1(val) when is_binary(val), do: :ok
        def validate_test_test1(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test__each({k, v}) do
          qmatch = case k do
            "test1" -> {validate_test_test1(v), true}
            _ -> {:ok, false}
          end

          {result, matched} = qmatch
          if matched, do: result, else: validate_test__additionalProperties(v)

        end

        def validate_test(val) when is_map(val), do: Enum.map(val, &__MODULE__.validate_test__each/1) |> Exonerate.error_reduction
        def validate_test(val), do: {:error, \"\#{inspect(val)} does not conform to JSON schema\"}
      """
    )
  end

  @tag :exonerate_codesynth
  test "object with required properties" do
    codesynth_match(
      %{
        "type" => "object",
        "properties" => %{"test1" => %{"type" => "string"}, "test2" => %{"type" => "integer"}},
        "required" => ["test1"]
      },
      """
        def validate_test_test1(val) when is_binary(val), do: :ok
        def validate_test_test1(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test_test2(val) when is_integer(val), do: :ok
        def validate_test_test2(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test__each({k, v}) do
          qmatch = case k do
            "test1" -> validate_test_test1(v)
            "test2" -> validate_test_test2(v)
            _ -> :ok
          end
        end

        def validate_test(val=%{"test1" => _}) when is_map(val), do: Enum.map(val, &__MODULE__.validate_test__each/1) |> Exonerate.error_reduction
        def validate_test(val) when is_map(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}
        def validate_test(val), do: {:error, \"\#{inspect(val)} does not conform to JSON schema\"}
      """
    )
  end

  @tag :exonerate_codesynth
  test "object with properties count restriction" do
    codesynth_match(%{"type" => "object", "minProperties" => 3, "maxProperties" => 5}, """
      def validate_test(val) when is_map(val), do: [Exonerate.Checkers.check_minproperties(val, 3), Exonerate.Checkers.check_maxproperties(val, 5)] |> Exonerate.error_reduction
      def validate_test(val), do: {:error, \"\#{inspect(val)} does not conform to JSON schema\"}
    """)
  end

  @tag :exonerate_codesynth
  test "object with a dependencies specification" do
    codesynth_match(
      %{
        "type" => "object",
        "properties" => %{"test1" => %{"type" => "string"}, "test2" => %{"type" => "integer"}},
        "dependencies" => %{"test1" => ["test2"]}
      },
      """
        def validate_test__deps_test1(val) do
          required_key_list = ["test2"]
          actual_key_list = Map.keys(val)

          is_valid = required_key_list |> Enum.all?(fn k -> k in actual_key_list end)
          if is_valid, do: :ok, else: {:error, "\#{inspect(val)} does not conform to JSON schema"}
        end

        def validate_test_test1(val) when is_binary(val), do: :ok
        def validate_test_test1(val), do: {:error, "\#{inspect(val)} does not conform to JSON schema"}

        def validate_test_test2(val) when is_integer(val), do: :ok
        def validate_test_test2(val), do: {:error, "\#{inspect(val)} does not conform to JSON schema"}

        def validate_test__deps(val) do
          depsmap = %{"test1" => &__MODULE__.validate_test__deps_test1/1}

          Map.keys(val)
          |> Enum.filter(&Map.has_key?(depsmap, &1))
          |> Enum.map(fn k -> depsmap[k].(val) end)
          |> Exonerate.error_reduction()
        end

        def validate_test__each({k, v}) do
          qmatch =
            case k do
              "test1" -> validate_test_test1(v)
              "test2" -> validate_test_test2(v)
              _ -> :ok
            end
        end

        def validate_test(val) when is_map(val), do: [validate_test__deps(val) | Enum.map(val, &__MODULE__.validate_test__each/1)] |> Exonerate.error_reduction()

        def validate_test(val), do: {:error, "\#{inspect(val)} does not conform to JSON schema"}
      """
    )
  end

  @tag :exonerate_codesynth
  test "object with pattern properties" do
    codesynth_match(
      %{
        "type" => "object",
        "properties" => %{"test1" => %{"type" => "string"}},
        "patternProperties" => %{"testp" => %{"type" => "integer"}}
      },
      """
        @patternprop_test_0 Regex.compile("testp") |> elem(1)

        def validate_test__pattern_0(val) when is_integer(val), do: :ok
        def validate_test__pattern_0(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test_test1(val) when is_binary(val), do: :ok
        def validate_test_test1(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test__each({k, v}) do
          pmatch = if Regex.match?(@patternprop_test_0, k), do: validate_test__pattern_0(v), else: :ok

          qmatch = case k do
            "test1" -> validate_test_test1(v)
            _ -> :ok
          end

          [qmatch, pmatch] |> Exonerate.error_reduction()

        end

        def validate_test(val) when is_map(val), do: Enum.map(val, &__MODULE__.validate_test__each/1) |> Exonerate.error_reduction
        def validate_test(val), do: {:error, \"\#{inspect(val)} does not conform to JSON schema\"}
      """
    )
  end

  @tag :exonerate_codesynth
  test "object with additional and standard properties" do
    codesynth_match(
      %{
        "type" => "object",
        "properties" => %{"test1" => %{"type" => "string"}},
        "additionalProperties" => false,
        "patternProperties" => %{"testp" => %{"type" => "integer"}}
      },
      """
        @patternprop_test_0 Regex.compile("testp") |> elem(1)

        def validate_test__pattern_0(val) when is_integer(val), do: :ok
        def validate_test__pattern_0(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test_test1(val) when is_binary(val), do: :ok
        def validate_test_test1(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test__each({k, v}) do
          pmatch = if Regex.match?(@patternprop_test_0, k), do: {validate_test__pattern_0(v), true}, else: {:ok, false}

          qmatch = case k do
            "test1" -> {validate_test_test1(v), true}
            _ -> {:ok, false}
          end

          {result, matched} = [qmatch, pmatch] |> Enum.unzip()

          if Enum.any?(matched), do: result |> Exonerate.error_reduction(), else: {:error, "does not conform to JSON schema"}
        end

        def validate_test(val) when is_map(val), do: Enum.map(val, &__MODULE__.validate_test__each/1) |> Exonerate.error_reduction
        def validate_test(val), do: {:error, \"\#{inspect(val)} does not conform to JSON schema\"}
      """
    )
  end

  @tag :exonerate_codesynth
  test "object with regex properties and a additional property schema" do
    codesynth_match(
      %{
        "type" => "object",
        "properties" => %{"test1" => %{"type" => "string"}},
        "additionalProperties" => %{"type" => "integer"},
        "patternProperties" => %{"testp" => %{"type" => "integer"}}
      },
      """
        @patternprop_test_0 Regex.compile("testp") |> elem(1)

        def validate_test__additionalProperties(val) when is_integer(val), do: :ok
        def validate_test__additionalProperties(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test__pattern_0(val) when is_integer(val), do: :ok
        def validate_test__pattern_0(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test_test1(val) when is_binary(val), do: :ok
        def validate_test_test1(val), do: {:error, "\#{inspect val} does not conform to JSON schema"}

        def validate_test__each({k, v}) do
          pmatch = if Regex.match?(@patternprop_test_0, k), do: {validate_test__pattern_0(v), true}, else: {:ok, false}

          qmatch = case k do
            "test1" -> {validate_test_test1(v), true}
            _ -> {:ok, false}
          end

          {result, matched} = [qmatch, pmatch] |> Enum.unzip()

          if Enum.any?(matched), do: result |> Exonerate.error_reduction(), else: validate_test__additionalProperties(v)
        end

        def validate_test(val) when is_map(val), do: Enum.map(val, &__MODULE__.validate_test__each/1) |> Exonerate.error_reduction
        def validate_test(val), do: {:error, \"\#{inspect(val)} does not conform to JSON schema\"}
      """
    )
  end
end
