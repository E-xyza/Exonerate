defmodule Exonerate.Formats.Regex do
  @moduledoc false

  # provides special code for a regex filter.  This only needs to be
  # dropped in once.  The macro uses the cache to track if it needs to
  # be created more than once or not.  Creates a function "~regex"
  # which returns `:ok` or `{:error, reason}` if it is a valid
  # regex.

  # the format is governed by the ECMA-262 standard:
  # https://www.ecma-international.org/publications-and-standards/standards/ecma-262/

  alias Exonerate.Cache

  defmacro filter do
    if Cache.register_context(__CALLER__.module, :"~regex") do
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

        defparsec(:"~regex", parsec(:Pattern) |> eos)
      end
    end
  end
end
