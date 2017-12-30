defmodule ExonerateValidationBasicTest.Helper do
  defmacro isvalid(schema) do
    quote do
      assert Exonerate.Validation.validate(unquote(schema)) == :ok
    end
  end

  defmacro notvalid(schema) do
    quote do
      refute Exonerate.Validation.validate(unquote(schema)) == :ok
    end
  end
end

defmodule ExonerateValidationBasicTest do
  use ExUnit.Case

  import ExonerateValidationBasicTest.Helper

  @tag :exonerate_validation
  test "boolean json schemas are valid" do
    isvalid(true)
    isvalid(false)
  end

  @tag :exonerate_validation
  test "empty json schemas are valid" do
    isvalid(%{})
  end

  @tag :exonerate_validation
  test "primitive json types are valid" do
    isvalid(%{"type" => "string"})
    isvalid(%{"type" => "integer"})
    isvalid(%{"type" => "number"})
    isvalid(%{"type" => "boolean"})
    isvalid(%{"type" => "null"})
    isvalid(%{"type" => "object"})
    isvalid(%{"type" => "array"})
  end

  @tag :exonerate_validation
  test "unknown parameters are invalid" do
    notvalid(%{"foo" => "bar"})
  end

  @tag :exonerate_validation
  test "multiparameter types are valid for type lists" do
    isvalid(%{"type" => ["integer", "string"]})
    notvalid(%{"type" => ["integer", "foo"]})
  end

  @tag :exonerate_validation
  test "minLength and maxLength are valid only for strings and friends" do
    isvalid(%{"type" => "string", "minLength" => 3})
    isvalid(%{"type" => "string", "maxLength" => 3})
    isvalid(%{"minLength" => 3})
    isvalid(%{"maxLength" => 3})
    isvalid(%{"type" => ["string", "integer"], "minLength" => 3})
    isvalid(%{"type" => ["string", "integer"], "maxLength" => 3})

    notvalid(%{"type" => "string", "maxLength" => "foo"})
    notvalid(%{"type" => "integer", "maxLength" => 3})
    notvalid(%{"type" => "number", "maxLength" => 3})
    notvalid(%{"type" => "null", "maxLength" => 3})
    notvalid(%{"type" => "integer", "minLength" => 3})
    notvalid(%{"type" => ["object", "integer"], "maxLength" => 3})
  end

  @tag :exonerate_validation
  test "pattern is valid only for strings." do
    isvalid(%{"type" => "string", "pattern" => "regex"})
    isvalid(%{"pattern" => "regex"})
    isvalid(%{"type" => ["string", "integer"], "pattern" => "regex"})

    notvalid(%{"type" => "string", "regex" => 3})
    notvalid(%{"type" => "integer", "regex" => "regex"})
    notvalid(%{"type" => "number", "regex" => "regex"})
    notvalid(%{"type" => "null", "regex" => "regex"})
    notvalid(%{"type" => ["number", "object"], "pattern" => "regex"})
  end

  @tag :exonerate_validation
  test "format is valid only for strings." do
    isvalid(%{"type" => "string", "format" => "uri"})
    isvalid(%{"format" => "uri"})
    isvalid(%{"type" => ["string", "integer"], "format" => "uri"})

    notvalid(%{"type" => "string", "format" => "foo"})
    notvalid(%{"type" => "integer", "format" => "uri"})
    notvalid(%{"type" => "number", "format" => "uri"})
    notvalid(%{"type" => "null", "format" => "uri"})
    notvalid(%{"type" => ["number", "object"], "format" => "uri"})
  end

  @tag :exonerate_validation
  test "multipleOf is valid only for numbers." do
    isvalid(%{"type" => "integer", "multipleOf" => 10})
    isvalid(%{"type" => "number", "multipleOf" => 10})
    isvalid(%{"multipleOf" => 10})
    isvalid(%{"type" => ["number", "object"], "multipleOf" => 10})
    isvalid(%{"type" => ["integer", "object"], "multipleOf" => 10})

    notvalid(%{"type" => "integer", "multipleOf" => "foo"})
    notvalid(%{"type" => "number", "multipleOf" => "foo"})
    notvalid(%{"type" => "string", "multipleOf" => 10})
    notvalid(%{"type" => "null", "multipleOf" => 10})
    notvalid(%{"type" => ["string", "object"], "multipleOf" => 10})
  end

  @tag :exonerate_validation
  test "minimum and maximum are valid only for numerics." do
    isvalid(%{"type" => "integer", "minimum" => 3})
    isvalid(%{"type" => "integer", "maximum" => 3})
    isvalid(%{"type" => "number", "minimum" => 3})
    isvalid(%{"type" => "number", "maximum" => 3})

    isvalid(%{"minimum" => 3})
    isvalid(%{"maximum" => 3})

    isvalid(%{"type" => ["string", "number"], "minimum" => 3})
    isvalid(%{"type" => ["string", "number"], "maximum" => 3})

    notvalid(%{"type" => "integer", "maximum" => "foo"})
    notvalid(%{"type" => "number", "minimum" => "foo"})
    notvalid(%{"type" => "string", "maximum" => 3})
    notvalid(%{"type" => "null", "minimum" => 3})
    notvalid(%{"type" => ["string", "object"], "maximum" => 3})
  end

  @tag :exonerate_validation
  test "exclusiveminmax is valid only when the corresponding exists" do
    isvalid(%{"type" => "integer", "minimum" => 3, "exclusiveMinimum" => true})
    isvalid(%{"type" => "integer", "maximum" => 3, "exclusiveMaximum" => true})
    isvalid(%{"type" => "number", "minimum" => 3, "exclusiveMinimum" => true})
    isvalid(%{"type" => "number", "maximum" => 3, "exclusiveMaximum" => true})

    notvalid(%{"type" => "integer", "maximum" => 3, "exclusiveMinimum" => true})
    notvalid(%{"type" => "integer", "minimum" => 3, "exclusiveMaximum" => true})
    notvalid(%{"type" => "integer", "exclusiveMinimum" => true})
    notvalid(%{"type" => "integer", "exclusiveMaximum" => true})
  end

  @tag :exonerate_validation
  test "properties is valid only for objects" do
    isvalid(%{"type" => "object", "properties" => %{}})
    isvalid(%{"properties" => %{}})
    isvalid(%{"type" => ["object", "number"], "properties" => %{}})

    notvalid(%{"type" => "object", "properties" => "not a map"})
    notvalid(%{"type" => "integer", "properties" => %{}})
    notvalid(%{"type" => "number", "properties" => %{}})
    notvalid(%{"type" => "string", "properties" => %{}})
    notvalid(%{"type" => "null", "properties" => %{}})
  end

  @tag :exonerate_validation
  test "properties properties must be valid json schemata" do
    isvalid(%{"type" => "object", "properties" => %{"subobj" => true}})
    isvalid(%{"type" => "object", "properties" => %{"subobj" => false}})
    isvalid(%{"type" => "object", "properties" => %{"subobj" => %{"type" => "string"}}})

    notvalid(%{"type" => "object", "properties" => %{"subobj" => %{"type" => "foo"}}})
    notvalid(%{"type" => "object", "properties" => %{"subobj" => %{"foo" => "bar"}}})

    notvalid(%{
      "type" => "object",
      "properties" => %{"subobj" => %{"type" => "string", "maximum" => 3}}
    })
  end

  @tag :exonerate_validation
  test "additional properties may be true, false, or a schema" do
    isvalid(%{"type" => "object", "properties" => %{}, "additionalProperties" => true})
    isvalid(%{"type" => "object", "properties" => %{}, "additionalProperties" => false})

    isvalid(%{
      "type" => "object",
      "properties" => %{},
      "additionalProperties" => %{"type" => "string"}
    })

    notvalid(%{"type" => "object", "properties" => %{}, "additionalProperties" => "not ok."})
    notvalid(%{"type" => "number", "additionalProperties" => true})

    notvalid(%{
      "type" => "object",
      "properties" => %{},
      "additionalProperties" => %{"foo" => "bar"}
    })

    notvalid(%{
      "type" => "object",
      "properties" => %{},
      "additionalProperties" => %{"type" => "foo"}
    })
  end

  @tag :exonerate_validation
  test "required properties must be inside the properties list" do
    isvalid(%{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"},
        "email" => %{"type" => "string"},
        "address" => %{"type" => "string"},
        "telephone" => %{"type" => "string"}
      },
      "required" => ["name", "email"]
    })

    notvalid(%{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"},
        "email" => %{"type" => "string"},
        "address" => %{"type" => "string"},
        "telephone" => %{"type" => "string"}
      },
      "required" => ["name", "foo"]
    })

    notvalid(%{"type" => "object", "required" => ["name", "foo"]})
    notvalid(%{"type" => "string", "required" => ["name", "foo"]})
  end

  @tag :exonerate_validation
  test "objects may have min/max property count" do
    isvalid(%{"type" => "object", "minProperties" => 3})
    isvalid(%{"type" => "object", "maxProperties" => 3})
    isvalid(%{"maxProperties" => 3})
    isvalid(%{"type" => ["object", "number"], "maxProperties" => 3})

    notvalid(%{"type" => "number", "maxProperties" => 3})
    notvalid(%{"type" => "integer", "maxProperties" => 3})
    notvalid(%{"type" => "null", "maxProperties" => 3})
    notvalid(%{"type" => ["null", "number"], "maxProperties" => 3})
  end

  @tag :exonerate_validation
  test "property dependencies work for both key lists and object descriptions" do
    # we're not going to assert that the existing keys must exist in properties property.
    isvalid(%{"type" => "object", "dependencies" => %{"credit_card" => ["billing_address"]}})
    notvalid(%{"type" => "object", "dependencies" => %{"credit_card" => [%{"foo" => "bar"}]}})
    isvalid(%{"type" => "object", "dependencies" => %{"credit_card" => %{"type" => "string"}}})
    notvalid(%{"type" => "object", "dependencies" => %{"credit_card" => %{"foo" => "bar"}}})
    notvalid(%{"type" => "object", "dependencies" => %{"credit_card" => %{"type" => "bar"}}})
    notvalid(%{"type" => "object", "dependencies" => %{"credit_card" => "billing_address"}})
  end

  @tag :exonerate_validation
  test "pattern properties have expected properties for objects" do
    isvalid(%{
      "type" => "object",
      "patternProperties" => %{"credit_card" => %{"type" => "string"}}
    })

    isvalid(%{"patternProperties" => %{"credit_card" => %{"type" => "string"}}})

    isvalid(%{
      "type" => ["object", "integer"],
      "patternProperties" => %{"credit_card" => %{"type" => "string"}}
    })

    notvalid(%{"type" => "object", "patternProperties" => %{"credit_card" => %{"foo" => "bar"}}})
    notvalid(%{"type" => "object", "patternProperties" => %{"credit_card" => %{"type" => "bar"}}})

    notvalid(%{
      "type" => "integer",
      "patternProperties" => %{"credit_card" => %{"type" => "string"}}
    })
  end

  @tag :exonerate_validation
  test "array items property works for a single schema" do
    # we're not going to assert that the existing keys must exist in properties property.
    isvalid(%{"type" => "array", "items" => %{"type" => "string"}})
    isvalid(%{"items" => %{"type" => "string"}})
    isvalid(%{"type" => ["array", "string"], "items" => %{"type" => "string"}})

    notvalid(%{"type" => "array", "items" => %{"type" => "foo"}})
    notvalid(%{"type" => "array", "items" => %{"foo" => "bar"}})
    notvalid(%{"type" => "array", "items" => "foo"})
    notvalid(%{"type" => "object", "items" => %{"type" => "string"}})
    notvalid(%{"type" => "string", "items" => %{"type" => "string"}})
  end

  @tag :exonerate_validation
  test "array items property works for an array schema" do
    # we're not going to assert that the existing keys must exist in properties property.
    isvalid(%{"type" => "array", "items" => [%{"type" => "string"}, %{"type" => "integer"}]})
    notvalid(%{"type" => "array", "items" => [%{"type" => "string"}, %{"type" => "foo"}]})
    notvalid(%{"type" => "array", "items" => [%{"type" => "string"}, %{"foo" => "bar"}]})
  end

  @tag :exonerate_validation
  test "additionalItems and uniqueItems works for arrays" do
    # we're not going to assert that the existing keys must exist in properties property.
    isvalid(%{"type" => "array", "uniqueItems" => true})
    isvalid(%{"type" => "array", "items" => [%{"type" => "string"}], "additionalItems" => true})

    isvalid(%{"uniqueItems" => true})
    isvalid(%{"items" => [%{"type" => "string"}], "additionalItems" => true})

    isvalid(%{"type" => ["array", "string"], "uniqueItems" => true})

    isvalid(%{
      "type" => ["array", "string"],
      "items" => [%{"type" => "string"}],
      "additionalItems" => true
    })

    notvalid(%{"type" => "string", "uniqueItems" => true})
    notvalid(%{"type" => "string", "additionalItems" => true})
  end

  @tag :exonerate_validation
  test "minItems and maxItems are valid only for arrays." do
    isvalid(%{"type" => "array", "minItems" => 3})
    isvalid(%{"type" => "array", "maxItems" => 3})
    isvalid(%{"maxItems" => 3})
    isvalid(%{"type" => ["array", "string"], "maxItems" => 3})

    notvalid(%{"type" => "array", "maxItems" => "foo"})
    notvalid(%{"type" => "string", "maxItems" => 3})
    notvalid(%{"type" => "integer", "maxItems" => 3})
    notvalid(%{"type" => "number", "maxItems" => 3})
    notvalid(%{"type" => "null", "maxItems" => 3})
    notvalid(%{"type" => "integer", "minItems" => 3})
    notvalid(%{"type" => ["null", "string"], "maxItems" => 3})
  end
end
