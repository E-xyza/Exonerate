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
  end

  # special extra formats.

  Exonerate.function_from_string(
    :def,
    :datetime_utc,
    ~s({"type": "string", "format": "date-time", "comment": "a"}),
    format: [{"date-time", [utc: true]}]
  )
end
