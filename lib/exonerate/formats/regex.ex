defmodule Exonerate.Formats.Regex do
  @moduledoc """
  Module which provides a macro that generates special code for an json
  pointer filter.

  the format is governed by the ECMA-262 standard:
  https://www.ecma-international.org/publications-and-standards/standards/ecma-262/
  """

  alias Exonerate.Cache

  @doc """
  Creates a `NimbleParsec` parser `~regex/1`.

  This function returns `{:ok, ...}` if the passed string is a valid regex,
  or `{:error, reason, ...}` if it is not.  See `NimbleParsec` for more
  information on the return tuples.

  The function will only be created once per module, and it is safe to call
  the macro more than once.

  ## Options:
  - `:name` (atom): the name of the function to create.  Defaults to
    `:"~regex"`
  """
  defmacro filter(opts \\ []) do
    name = Keyword.get(opts, :name, :"~regex")

    if Cache.register_context(__CALLER__.module, name) do
      quote do
        require Pegasus
        import NimbleParsec

        Pegasus.parser_from_string(~S"""
        Pattern <- Disjunction*
        Disjunction <- Term / (Term "|" Disjunction)
        Term <- Assertion / (Atom Quantifier) / Atom
        Assertion <- "^" / "$" / "\\b" / "\\B" /
          (("(?=" / "(?!" / "(?<=" / "(<!") Disjunction ")")
        Quantifier <- QuantifierPrefix "?"?
        QuantifierPrefix <- "*" / "+" / "?" / ("{" DecimalDigits ","? DecimalDigits? "}")
        Atom <- "." /
          "\\" AtomEscape /
          "(?:" Disjunction ")" /
          "(" GroupSpecifier? Disjunction ")" /
          CharacterClass /
          PatternCharacter
        AtomEscape <- DecimalEscape / CharacterClassEscape / CharacterEscape / "k" GroupName
        CharacterEscape <- ControlEscape / "c" ControlLetter / Zero
        ControlEscape <- "f" / "n" / "r" / "t" / "v"
        ControlLetter <- [a-zA-Z]
        GroupSpecifier <- "?" GroupName
        GroupName <- "<" RegExpIdentifierName ">"

        RegExpIdentifierName <-
          RegExpIdentifierStart RegExpIdentifierPart*

        RegExpIdentifierStart <-
          IdentifierStartChar /
          "\\" RegExpUnicodeEscapeSequence /
          Utf8Char

        RegExpIdentifierPart <-
            IdentifierPartChar /
            "\\" RegExpUnicodeEscapeSequence /
            Utf8Char

        RegExpUnicodeEscapeSequence <-
            "u" HexLeadSurrogate "\\u" HexTrailSurrogate /
            "u" HexLeadSurrogate /
            "u" HexTrailSurrogate /
            "u" HexNonSurrogate /
            "u" HexDigit HexDigit HexDigit HexDigit /
            "u{" CodePoint "}"

        IdentifierStartChar <- "$" / "-"
        IdentifierPartChar <- "$"

        HexLeadSurrogate <- HexDigit HexDigit HexDigit HexDigit
        HexTrailSurrogate <- HexDigit HexDigit HexDigit HexDigit
        HexNonSurrogate <- HexDigit HexDigit HexDigit HexDigit

        HexDigit <- [0-9a-fA-F]
        CodePoint <- HexDigit HexDigit? HexDigit? HexDigit? HexDigit? HexDigit?

        DecimalEscape <- [1-9] [0-9]*
        CharacterClassEscape <- "d" / "D" / "s" / "S" / "w" / "W" /
          "p{" UnicodePropertyValueExpression "}" /
          "P{" UnicodePropertyValueExpression "}"

        UnicodePropertyValueExpression <-
          UnicodePropertyName "=" UnicodePropertyValue /
          LoneUnicodePropertyNameOrValue

        UnicodePropertyName <- UnicodePropertyNameCharacters
        UnicodePropertyNameCharacters <- UnicodePropertyNameCharacter+
        UnicodePropertyValue <- UnicodePropertyValueCharacters
        LoneUnicodePropertyNameOrValue <- UnicodePropertyNameCharacters
        UnicodePropertyNameCharacter <- ControlLetter / "_"

        UnicodePropertyValueCharacters <- UnicodePropertyValueCharacters
        UnicodePropertyValueCharacter <- UnicodePropertyNameCharacter / DecimalDigit

        DecimalDigit <- [0-9]
        DecimalDigits <-
           DecimalDigit+ "_" DecimalDigits /
           DecimalDigit+

        CharacterClass <- "[^" ClassRanges "]" / "[" ClassRanges "]"
        ClassRanges <- NonemptyClassRanges / ""
        NonemptyClassRanges <-
          ClassAtom "-" ClassAtom ClassRanges /
          ClassAtom NonemptyClassRangesNoDash /
          ClassAtom
        NonemptyClassRangesNoDash <-
          ClassAtomNoDash NonemptyClassRangesNoDash /
          ClassAtomNoDash "-" ClassAtom /
          ClassRanges /
          ClassAtom

        ClassAtom <- "-" / ClassAtomNoDash
        ClassAtomNoDash <- ClassAtomSource / "\\" ClassEscape
        ClassEscape <- "b" / "-" / CharacterClassEscape / CharacterEscape
        """)

        defcombinatorp(:Utf8Char, utf8_char(not: 0))

        defcombinatorp(
          :PatternCharacter,
          utf8_char(
            not: ?^,
            not: ?$,
            not: ?\\,
            not: ?.,
            not: ?*,
            not: ?+,
            not: ??,
            not: ?(,
            not: ?),
            not: ?[,
            not: ?],
            not: ?{,
            not: ?},
            not: ?|
          )
        )

        defcombinatorp(:Zero, ascii_char(~C'0') |> lookahead_not(ascii_char([?0..?9])))

        defcombinatorp(:ClassAtomSource, utf8_char(not: ?\\, not: ?], not: ?-))

        defparsec(unquote(name), parsec(:Pattern) |> eos)
      end
    end
  end
end
