defmodule ExonerateTest.IdnHostnameTest do
  use ExUnit.Case, async: true

  alias Exonerate.Formats.IdnHostname
  require IdnHostname

  # generate filter accessory functions
  IdnHostname.filter()

  @tests %{
    "a" => {"a-", "Only ASCII characters, one, lowercase."},
    "A" => {"A-", "Only ASCII characters, one, uppercase."},
    "3" => {"3-", "Only ASCII characters, one, a digit."},
    "-" => {"--", "Only ASCII characters, one, a hyphen."},
    "--" => {"---", "Only ASCII characters, two hyphens."},
    "London" => {"London-", "Only ASCII characters, more than one, no hyphens."},
    "Lloyd-Atkinson" => {"Lloyd-Atkinson-", "Only ASCII characters, one hyphen."},
    "This has spaces" => {"This has spaces-", "Only ASCII characters, with spaces."},
    "-> $1.00 <-" => {"-> $1.00 <--", "Only ASCII characters, mixed symbols."},
    "а" => {"80a", "No ASCII characters, one Cyrillic character."},
    "ü" => {"tda", "No ASCII characters, one Latin-1 Supplement character."},
    "α" => {"mxa", "No ASCII characters, one Greek character."},
    "例" => {"fsq", "No ASCII characters, one CJK character."},
    "😉" => {"n28h", "No ASCII characters, one emoji character."},
    "αβγ" => {"mxacd", "No ASCII characters, more than one character."},
    "München" =>
      {"Mnchen-3ya", "Mixed string, with one character that is not an ASCII character."},
    "Mnchen-3ya" => {"Mnchen-3ya-", "Double-encoded Punycode of \"München\"."},
    "München-Ost" =>
      {"Mnchen-Ost-9db", "Mixed string, with one character that is not ASCII, and a hyphen."},
    "Bahnhof München-Ost" =>
      {"Bahnhof Mnchen-Ost-u6b",
       "Mixed string, with one space, one hyphen, and one character that is not ASCII."},
    "abæcdöef" => {"abcdef-qua4k", "Mixed string, two non-ASCII characters."},
    "правда" => {"80aafi6cg", "Russian, without ASCII."},
    "ยจฆฟคฏข" => {"22cdfh1b8fsa", "Thai, without ASCII."},
    "도메인" => {"hq1bm8jm9l", "Korean, without ASCII."},
    "ドメイン名例" => {"eckwd4c7cu47r2wf", "Japanese, without ASCII."},
    "MajiでKoiする5秒前" => {"MajiKoi5-783gue6qz075azm5e", "Japanese with ASCII."},
    "「bücher」" => {"bcher-kva8445foa", "Mixed non-ASCII scripts (Latin-1 Supplement and CJK)."}
  }

  describe "the idna/punycode library can" do
    for {unicode, {punycode, testdesc}} <- @tests do
      test "decode #{testdesc}" do
        assert String.to_charlist(unquote(unicode)) ==
                 :punycode.decode(String.to_charlist(unquote(punycode)))
      end
    end

    for {unicode, {punycode, testdesc}} <- @tests do
      test "encode #{testdesc}" do
        assert String.to_charlist(unquote(punycode)) ==
                 :punycode.encode(String.to_charlist(unquote(unicode)))
      end
    end
  end

  describe "punycode segment analysis" do
    defp segment(string, acc, state),
      do: unquote(:"~idn-hostname:punycode-segment")(string, acc, state)

    # test that the punycode prefix testing works
    for {unicode, {punycode, testdesc}} <- @tests do
      test "segment characterization for #{testdesc}" do
        size = byte_size(unquote(punycode)) + 4
        {:cont, {:ok, [unquote(unicode)], ^size}} = segment("xn--" <> unquote(punycode), {:ok, [], 0}, nil)
      end
    end

    test "fails when punycode contains non-ascii character" do
      {:halt, {:error, "invalid punycode content" <> _}} = segment("xn--😉", {:ok, [], 0}, nil)
    end

    test "fails when punycode length is greater than segment size" do
      {:halt, {:error, "exceeds hostname label length limit"}} = segment("xn--abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefgh-", {:ok, [], 0}, nil)
    end

    test "" do
      {:halt, {:error, "exceeds hostname length limit"}} = segment("xn--a", {:ok, [], 252}, nil)
    end
  end
end
