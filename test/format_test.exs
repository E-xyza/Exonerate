defmodule ExonerateTest.FormatTest do
  use ExUnit.Case, async: true
  require Exonerate

  describe "builtin formats:" do
    Exonerate.function_from_string(:def, :datetime, ~s({"type": "string", "format": "date-time"}),
      format: :default
    )

    test "date-time" do
      assert :ok == datetime(to_string(DateTime.utc_now()))
      assert :ok == datetime(to_string(NaiveDateTime.utc_now()))
      assert {:error, _} = datetime(to_string(Date.utc_today()))
      assert {:error, _} = datetime(to_string(Time.utc_now()))
      assert {:error, _} = datetime("foobar")
    end

    Exonerate.function_from_string(:def, :date, ~s({"type": "string", "format": "date"}),
      format: :default
    )

    test "date" do
      assert :ok == date(to_string(Date.utc_today()))
      assert {:error, _} = date(to_string(DateTime.utc_now()))
      assert {:error, _} = date(to_string(Time.utc_now()))
      assert {:error, _} = date("foobar")
    end

    Exonerate.function_from_string(:def, :time, ~s({"type": "string", "format": "time"}),
      format: :default
    )

    test "time" do
      assert :ok == time(to_string(Time.utc_now()))
      assert {:error, _} = time(to_string(DateTime.utc_now()))
      assert {:error, _} = time(to_string(Date.utc_today()))
      assert {:error, _} = time("foobar")
    end

    Exonerate.function_from_string(:def, :duration, ~s({"type": "string", "format": "duration"}),
      format: :default
    )

    test "duration" do
      assert :ok == duration("P10Y10M10DT10H10M10S")
      assert :ok == duration("P10M10DT10H10M10S")
      assert :ok == duration("P10DT10H10M10S")
      assert :ok == duration("PT10H10M10S")
      assert :ok == duration("PT10M10S")
      assert :ok == duration("PT10S")

      assert {:error, _} = duration("P10Y10Y10")
      assert {:error, _} = duration("foobar")
    end

    Exonerate.function_from_string(:def, :email, ~s({"type": "string", "format": "email"}),
      format: :default
    )

    test "email" do
      assert :ok == email("foo@ba")
      assert {:error, _} = email("foobar")
    end

    Exonerate.function_from_string(
      :def,
      :idn_email,
      ~s({"type": "string", "format": "idn-email"}),
      format: :default
    )

    test "idn-email" do
      assert :ok == idn_email("ಬೆಂಬಲ@ಡೇಟಾಮೇಲ್.ಭಾರತ")
      assert {:error, _} = idn_email("ಭಾರತ")
    end

    Exonerate.function_from_string(
      :def,
      :hostname,
      ~s({"type": "string", "format": "hostname"}),
      format: :default
    )

    test "hostname" do
      assert :ok == hostname("foo.bar")
      assert {:error, _} = hostname("character!notallowed.foo")
    end

    Exonerate.function_from_string(
      :def,
      :idn_hostname,
      ~s({"type": "string", "format": "idn-hostname"}),
      format: :default
    )

    test "idn-hostname" do
      assert :ok == idn_hostname("foo.bar")
      assert :ok == idn_hostname("ಡೇಟಾಮೇಲ್.ಭಾರತ")
      assert {:error, _} = idn_hostname("ಡೇಟಾ!ಮೇಲ್.ಭಾರತ")
    end

    Exonerate.function_from_string(
      :def,
      :ipv4,
      ~s({"type": "string", "format": "ipv4"}),
      format: :default
    )

    test "ipv4" do
      assert :ok == ipv4("127.0.0.1")
      assert {:error, _} = ipv4("foo.bar")
    end

    Exonerate.function_from_string(
      :def,
      :ipv6,
      ~s({"type": "string", "format": "ipv6"}),
      format: :default
    )

    test "ipv6" do
      assert :ok == ipv6("::1")
      assert :ok == ipv6("0:0:0:0:0:0:0:1")
      assert {:error, _} = ipv6("foo.bar")
      assert {:error, _} = ipv6("127.0.0.1")
    end

    Exonerate.function_from_string(
      :def,
      :uri,
      ~s({"type": "string", "format": "uri"}),
      format: :default
    )

    test "uri" do
      assert :ok == uri("http://foo.bar/baz#quux")
      assert {:error, _} = uri("/baz#quux")
      assert {:error, _} = uri("foo.bar")
    end

    Exonerate.function_from_string(
      :def,
      :uri_reference,
      ~s({"type": "string", "format": "uri-reference"}),
      format: :default
    )

    test "uri_reference" do
      assert :ok == uri_reference("http://foo.bar/baz#quux")
      assert :ok = uri_reference("/baz#quux")
      assert {:error, _} = uri_reference("/foo.bar#aaa#bbb")
    end

    Exonerate.function_from_string(
      :def,
      :uuid,
      ~s({"type": "string", "format": "uuid"}),
      format: :default
    )

    test "uuid" do
      assert :ok == uuid("123e4567-e89b-12d3-a456-426614174000")
      assert {:error, _} = uuid("foo.bar")
    end
  end

  # special extra formats.
  describe "special date-time formats" do
    Exonerate.function_from_string(
      :def,
      :datetime_tz,
      ~s({"type": "string", "format": "date-time-tz"}),
      format: :default
    )

    test "date-time-tz" do
      assert :ok == datetime_tz("#{DateTime.utc_now()}")

      {:ok, tz_dt} = DateTime.now("America/Chicago")
      tzstring = String.replace_trailing("#{tz_dt}", " CDT America/Chicago", "")

      assert :ok == datetime_tz(tzstring)
      assert {:error, _} = datetime_tz("#{NaiveDateTime.utc_now()}")
      assert {:error, _} = datetime_tz("foo.bar")
    end

    Exonerate.function_from_string(
      :def,
      :datetime_utc,
      ~s({"type": "string", "format": "date-time-utc"}),
      format: :default
    )

    test "date-time-utc" do
      assert :ok == datetime_utc("#{DateTime.utc_now()}")

      {:ok, tz_dt} = DateTime.now("America/Chicago")
      tzstring = String.replace_trailing("#{tz_dt}", " CDT America/Chicago", "")

      assert {:error, _} = datetime_utc(tzstring)
      assert {:error, _} = datetime_utc("#{NaiveDateTime.utc_now()}")
      assert {:error, _} = datetime_utc("foo.bar")
    end
  end

  describe "a format that isn't defined is ignored" do
    Exonerate.function_from_string(
      :def,
      :not_defined,
      ~s({"type": "string", "format": "not-defined"}),
      format: :default
    )

    test "works fine" do
      assert :ok == not_defined("foobar")
    end
  end

  defmodule Custom do
    def validate("foo"), do: :ok
    def validate(_), do: {:error, "must be foo"}

    def custom("bar"), do: :ok
    def custom(_), do: {:error, "must be bar"}

    def custom(str, str), do: :ok
    def custom(_, str), do: {:error, "must be #{str}"}
  end

  describe "formats can be targetted by type" do
    Exonerate.function_from_string(
      :def,
      :custom_module,
      ~s({"type": "string", "format": "custom"}),
      format: [types: [{"custom", Custom}]]
    )

    test "by custom module" do
      assert :ok == custom_module("foo")
      assert {:error, opts} = custom_module("bar")
      assert opts[:reason] == "must be foo"
    end

    Exonerate.function_from_string(
      :def,
      :custom_module_function,
      ~s({"type": "string", "format": "custom"}),
      format: [types: [{"custom", {Custom, :custom}}]]
    )

    test "by custom module and function" do
      assert :ok == custom_module_function("bar")
      assert {:error, opts} = custom_module_function("baz")
      assert opts[:reason] == "must be bar"
    end

    Exonerate.function_from_string(
      :def,
      :custom_module_function_args,
      ~s({"type": "string", "format": "custom"}),
      format: [types: [{"custom", {Custom, :custom, ["baz"]}}]]
    )

    test "by custom module and function and extra args" do
      assert :ok == custom_module_function_args("baz")
      assert {:error, opts} = custom_module_function_args("quux")
      assert opts[:reason] == "must be baz"
    end

    Exonerate.function_from_string(
      :def,
      :override_default_module,
      """
      {
        "type": "object",
        "properties": {
            "uuid": {"type": "string", "format": "uuid"},
            "foo": {"type": "string", "format": "date-time"}
        }
      }
      """,
      format: [types: [{"date-time", Custom}], default: true]
    )

    test "defaulted format works" do
      assert :ok == override_default_module(%{"uuid" => "123e4567-e89b-12d3-a456-426614174000"})
      assert {:error, _} = override_default_module(%{"uuid" => "foo.bar"})
    end

    test "overridden" do
      assert :ok == override_default_module(%{"foo" => "foo"})
      assert {:error, _} = override_default_module(%{"foo" => "#{DateTime.utc_now()}"})
    end
  end

  describe "formats can be targeted by JsonPointer" do
    Exonerate.function_from_string(
      :def,
      :path_relative,
      ~s({"type": "string", "format": "custom"}),
      format: [at: [{"#/", Custom}]]
    )

    test "using relative path" do
      assert :ok == path_relative("foo")
      assert {:error, opts} = path_relative("bar")
      assert opts[:reason] == "must be foo"
    end

    Exonerate.function_from_string(
      :def,
      :path_override,
      """
      {
        "type": "object",
        "properties": {
            "uuid": {"type": "string", "format": "uuid"},
            "foo": {"type": "string", "format": "date-time"}
        }
      }
      """,
      format: [at: [{"#/properties/foo", Custom}], default: true]
    )

    test "defaulted format works" do
      assert :ok == path_override(%{"uuid" => "123e4567-e89b-12d3-a456-426614174000"})
      assert {:error, _} = path_override(%{"uuid" => "foo.bar"})
    end

    test "overridden" do
      assert :ok == path_override(%{"foo" => "foo"})
      assert {:error, _} = path_override(%{"foo" => "#{DateTime.utc_now()}"})
    end

    Exonerate.function_from_string(
      :def,
      :absolute_path,
      """
      {
        "type": "object",
        "$id": "http://localhost:6666/my-schema.json",
        "properties": {
            "foo": {"type": "string", "format": "custom"}
        }
      }
      """,
      format: [
        at: [{"http://localhost:6666/my-schema.json#/properties/foo", Custom}],
        default: true
      ]
    )

    test "using id'd path" do
      assert :ok == absolute_path(%{"foo" => "foo"})
      assert {:error, _} = absolute_path(%{"foo" => "bar"})
    end
  end
end
