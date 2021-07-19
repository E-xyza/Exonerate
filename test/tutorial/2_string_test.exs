defmodule ExonerateTest.Tutorial.StringTest do
  use ExUnit.Case, async: true

  @moduletag :string

  @moduledoc """
  basic tests from:

  https://json-schema.org/understanding-json-schema/reference/string.html

  Literally conforms to all the tests presented in this document.
  """

  @moduletag :tutorial

  defmodule String do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/string.html#string
    """
    require Exonerate

    Exonerate.function_from_string(:def, :string, ~s({ "type": "string" }))
  end

  describe "basic strings example" do
    test "various strings match correctly" do
      assert :ok = String.string("This is a string")
      assert :ok = String.string("Déjà vu")
      assert :ok = String.string("")
      assert :ok = String.string("42")
    end

    test "number mismatches a string" do
      assert {:error, list} = String.string(42)

      assert list[:schema_pointer] == "/type"
      assert list[:error_value] == 42
      assert list[:json_pointer] == "/"
    end
  end

  defmodule Length do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/string.html#string
    """
    require Exonerate

    Exonerate.function_from_string(:def, :string, """
                      {
                        "type": "string",
                        "minLength": 2,
                        "maxLength": 3
                      }
                      """)
  end

  describe "strings length example" do
    test "string of correct sizes match" do
      assert :ok = Length.string("AB")
      assert :ok = Length.string("ABC")
    end

    test "string of incorrect sizes don't match" do
      assert {:error, list} = Length.string("A")

      assert list[:schema_pointer] == "/minLength"
      assert list[:error_value] == "A"
      assert list[:json_pointer] == "/"

      assert {:error, list} = Length.string("ABCD")

      assert list[:schema_pointer] == "/maxLength"
      assert list[:error_value] == "ABCD"
      assert list[:json_pointer] == "/"
    end
  end

  defmodule Pattern do

    @moduledoc """
    tests from:

    https://json-schema.org/understanding-json-schema/reference/string.html#regular-expressions
    """
    require Exonerate

    Exonerate.function_from_string(:def, :string, """
                      {
                        "type": "string",
                        "pattern": "^(\\\\([0-9]{3}\\\\))?[0-9]{3}-[0-9]{4}$"
                      }
                      """)
  end

  describe "strings pattern example" do
    test "telephone numbers match" do
      assert :ok = Pattern.string("555-1212")
      assert :ok = Pattern.string("(888)555-1212")
    end

    test "string of incorrect patterns don't match" do
      assert {:error, list} =
        Pattern.string("(888)555-1212 ext. 532")

      assert list[:schema_pointer] == "/pattern"
      assert list[:error_value] == "(888)555-1212 ext. 532"
      assert list[:json_pointer] == "/"

      assert {:error, list} =
        Pattern.string("(800)FLOWERS")

      assert list[:schema_pointer] == "/pattern"
      assert list[:error_value] == "(800)FLOWERS"
      assert list[:json_pointer] == "/"
    end
  end

  defmodule Format do
    require Exonerate

    defmodule Custom do
      def format("ok"), do: true
      def format(_), do: false

      def format(a, a), do: true
      def format(_, _), do: false
    end

    Exonerate.function_from_string(:def, :datetime, ~s({"type": "string", "format": "date-time"}))
    Exonerate.function_from_string(:def, :datetime_utc, ~s({"type": "string", "format": "date-time", "comment": "a"}),
      format: %{"/" => [:utc]})
    Exonerate.function_from_string(:def, :datetime_disabled, ~s({"type": "string", "format": "date-time", "comment": "b"}),
      format: %{"/" => false})
    Exonerate.function_from_string(:def, :datetime_custom, ~s({"type": "string", "format": "date-time", "comment": "c"}),
      format: %{"/" => {Custom, :format, []}})
    Exonerate.function_from_string(:def, :datetime_custom_params, ~s({"type": "string", "format": "date-time", "comment": "d"}),
      format: %{"/" => {Custom, :format, ["ok"]}})
    Exonerate.function_from_string(:def, :datetime_custom_private, ~s({"type": "string", "format": "date-time", "comment": "e"}),
      format: %{"/" => {:format, []}})
    Exonerate.function_from_string(:def, :datetime_custom_private_params, ~s({"type": "string", "format": "date-time", "comment": "f"}),
      format: %{"/" => {:format, ["ok"]}})

    Exonerate.function_from_string(:def, :date, ~s({"type": "string", "format": "date"}))

    Exonerate.function_from_string(:def, :time, ~s({"type": "string", "format": "time"}))

    Exonerate.function_from_string(:def, :uuid, ~s({"type": "string", "format": "uuid"}))

    Exonerate.function_from_string(:def, :ipv4, ~s({"type": "string", "format": "ipv4"}))

    Exonerate.function_from_string(:def, :ipv6, ~s({"type": "string", "format": "ipv6"}))

    Exonerate.function_from_string(:def, :custom, ~s({"type": "string", "format": "custom", "comment": "a"}),
        format: %{"/" => {Custom, :format, ["ok"]}})

    Exonerate.function_from_string(:def, :custom_private, ~s({"type": "string", "format": "custom", "comment": "b"}),
        format: %{"/" => {:format, ["ok"]}})

    Exonerate.function_from_string(:def, :custom_broad, ~s({"type": "string", "format": "custom"}),
        format: %{custom: {Custom, :format, ["ok"]}})

    defp format("ok"), do: true
    defp format(_), do: false

    defp format(a, a), do: true
    defp format(_, _), do: false
  end

  describe "formats:" do
    test "date-time" do
      assert :ok == Format.datetime(to_string(DateTime.utc_now()))
      assert :ok == Format.datetime(to_string(NaiveDateTime.utc_now()))
      assert {:error, _} = Format.datetime(to_string(Date.utc_today()))
      assert {:error, _} = Format.datetime(to_string(Time.utc_now()))
      assert {:error, _} = Format.datetime("foobar")
    end

    test "date-time-utc" do
      assert :ok == Format.datetime_utc(to_string(DateTime.utc_now()))
      assert {:error, _} = Format.datetime_utc(to_string(NaiveDateTime.utc_now()))
    end

    test "date-time-disabled" do
      assert :ok == Format.datetime_disabled("foobar")
    end

    test "date-time-custom" do
      assert :ok == Format.datetime_custom("ok")
      assert {:error, _} = Format.datetime_custom("bar")
    end

    test "date-time-custom-params" do
      assert :ok == Format.datetime_custom_params("ok")
      assert {:error, _} = Format.datetime_custom_params("bar")
    end

    test "date-time-custom-private" do
      assert :ok == Format.datetime_custom_private("ok")
      assert {:error, _} = Format.datetime_custom_private("bar")
    end

    test "date-time-custom-private-params" do
      assert :ok == Format.datetime_custom_private_params("ok")
      assert {:error, _} = Format.datetime_custom_private_params("bar")
    end

    test "date" do
      assert :ok == Format.date(to_string(Date.utc_today()))
      assert {:error, _} = Format.date("foo")
    end

    test "time" do
      assert :ok == Format.time(to_string(Time.utc_now()))
      assert {:error, _} = Format.time("foo")
    end

    test "ipv4" do
      assert :ok == Format.ipv4("10.10.10.10")
      assert {:error, _} = Format.ipv4("256.10.10.10")
    end

    test "ipv6" do
      assert :ok == Format.ipv6("::1")
      assert {:error, _} = Format.ipv6("foo")
    end

    test "custom" do
      assert :ok == Format.custom("ok")
      assert {:error, _} = Format.custom("foo")
    end

    test "custom-private" do
      assert :ok == Format.custom_private("ok")
      assert {:error, _} = Format.custom_private("foo")
    end

    test "custom-broad" do
      assert :ok == Format.custom_broad("ok")
      assert {:error, _} = Format.custom_broad("foo")
    end
  end
end
