defmodule ExonerateTest.FormatTest do
  use ExUnit.Case, async: true

  require Exonerate

  describe "builtin formats:" do
    Exonerate.function_from_string(:def, :datetime, ~s({"type": "string", "format": "date-time"}),
      format: true
    )

    test "date-time" do
      assert :ok == datetime(to_string(DateTime.utc_now()))
      assert :ok == datetime(to_string(NaiveDateTime.utc_now()))
      assert {:error, _} = datetime(to_string(Date.utc_today()))
      assert {:error, _} = datetime(to_string(Time.utc_now()))
      assert {:error, _} = datetime("foobar")
    end

    Exonerate.function_from_string(:def, :date, ~s({"type": "string", "format": "date"}),
      format: true
    )

    test "date" do
      assert :ok == date(to_string(Date.utc_today()))
      assert {:error, _} = date(to_string(DateTime.utc_now()))
      assert {:error, _} = date(to_string(Time.utc_now()))
      assert {:error, _} = date("foobar")
    end

    Exonerate.function_from_string(:def, :time, ~s({"type": "string", "format": "time"}),
      format: true
    )

    test "time" do
      assert :ok == time(to_string(Time.utc_now()))
      assert {:error, _} = time(to_string(DateTime.utc_now()))
      assert {:error, _} = time(to_string(Date.utc_today()))
      assert {:error, _} = time("foobar")
    end

    Exonerate.function_from_string(:def, :duration, ~s({"type": "string", "format": "duration"}),
      format: true
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
      format: true
    )

    test "email" do
      assert :ok == email("foo@ba")
      assert {:error, _} = email("foobar")
    end

    Exonerate.function_from_string(
      :def,
      :idn_email,
      ~s({"type": "string", "format": "idn-email"}),
      format: true
    )

    test "idn-email" do
      assert :ok == idn_email("ಬೆಂಬಲ@ಡೇಟಾಮೇಲ್.ಭಾರತ")
      assert {:error, _} = idn_email("ಭಾರತ")
    end

    Exonerate.function_from_string(
      :def,
      :hostname,
      ~s({"type": "string", "format": "hostname"}),
      format: true
    )

    test "hostname" do
      assert :ok == hostname("foo.bar")
      assert {:error, _} = hostname("character!notallowed.foo")
    end

    Exonerate.function_from_string(
      :def,
      :idn_hostname,
      ~s({"type": "string", "format": "idn-hostname"}),
      format: true
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
      format: true
    )

    test "ipv4" do
      assert :ok == ipv4("127.0.0.1")
      assert {:error, _} = ipv4("foo.bar")
    end

    Exonerate.function_from_string(
      :def,
      :ipv6,
      ~s({"type": "string", "format": "ipv6"}),
      format: true
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
      format: true
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
      format: true
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
      format: true
    )

    test "uuid" do
      assert :ok == uuid("123e4567-e89b-12d3-a456-426614174000")
      assert {:error, _} = uuid("foo.bar")
    end
  end

  # special extra formats.

  Exonerate.function_from_string(
    :def,
    :datetime_utc,
    ~s({"type": "string", "format": "date-time", "comment": "a"}),
    format: [{"date-time", [utc: true]}]
  )
end
