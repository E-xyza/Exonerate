"""
Pattern <- Disjunction
Disjuction <- Alternative / (Alternative "|" Disjunction)
Alternative <- "" / (Alternative Term)
Term <- Assertion / Atom / (Atom Quantifier)
Assertion <- "^" / "$" / "\\b" / "\\B" /
  (("(?=" / "(?!" / "(?<=" / "(<!") Disjunction ")")
Quantifier <- QuantifierPrefix / (QuantifierPrefix "?")
QuantifierPrefix <- "*" / "+" / "?" / ("{" DecimalDigits ","? DecimalDigits? "}")
Atom <- PatternCharacter /
        "." /
        ("\\" AtomEscape) /
        CharcterClass /
        ("(" (GroupSpecifier / "?:") Disjunction ")")
SyntaxCharacter <- "^" / "$" / "\\" / "." / "*" / "+" / "?" / "(" / ")" / "[" / "]" / "{" / "}" / "|" / "/"
PatternCharacter <- "foo" # TODO
AtomEscape <-
  DecimalEscape / CharacterClassEscape / CharacterEscape / ("k" GroupName)
CharacterEscape <-
  ControlEscape / ("c" ControlLetter) / #BLABLA
ControlEscape <- "f" / "n" / "r" / "t" / "v"
ControlLetter <- [a-zA-Z]
GroupSpecifier <- "" / ("?" GroupName)
GroupName <- "<" RegExpIdentifierName ">"
RegExpIdentifierName <-
  RegExpIdentifierStart / RegExpIdentifierName RegExpIdentifierPart
RegExpIdentifierStart <- IdentifierStartChar /
  ("\\" RegExpUnicodeEscapeSequence) /
  (UnicodeLeadSurrogate UnicodeTrailSurrogate)
RegExpIdentifierPart <-
   IdentifierPartChar /
  ("\\" RegExpUnicodeEscapeSequence) /
  (UnicodeLeadSurrogate UnicodeTrailSurrogate)
RegExpUnicodeEscapeSequence <-
  "u" HexLeadSurrogate "\\u" HexTrailSurrogate /
  "u" HexLeadSurrogate /
  "u" HexTrailSurrogate /
  "u" HexNonSurrogate /
  "u" HexDigit HexDigit HexDigit HexDigit /
  "u{" CodePoint "}"
UnicodeLeadSurrogate <- #TODO
UnicodeTrailSurrogate <- #TODO
HexLeadSurrogate <- HexDigit HexDigit HexDigit HexDigit
HexTrailSurrogate <- HexDigit HexDigit HexDigit HexDigit
HexNonSurrogate <- HexDigit HexDigit HexDigit HexDigit
IdentityEscape <- # TODO
DecimalEscape <- #TODO
CharacterClassEscape <- "d" / "D" / "s" / "S" / "w" / "W" /
  ("p" "{" UnicodePropertyValueExpression "}") /
  ("P" "{" UnicodePropertyValueExpression "}")
UnicodePropertyValueExpression <-
  UnicodePropertyName "=" UnicodePropertyValue /
  LoneUnicodePropertyNameOrValue
UnicodePropertyName <- UnicodePropertyNameCharacters
UnicodePropertyNameCharacters <- UnicodePropertyNameCharacter+
UnicodeProertyValue <- UnicodePropertyValueCharacters
LoneUnicodePropertyNameOrValue <- UnicodePropertyNameCharacters
UnicodePropertyValueCharacters <- UnicodePropertyValueCharacters
UnicodePropertyValueCharacter <- UnicodePropertyNameCharacter / DecmalDigit
UnicodePropertyNameCharacter <- ControlLetter / "_"
CharacterClass <- #TODO
ClassRanges <- "" / NonemptyClassRanges
NonemptyClassRanges <- ClassAtom /
  ClassAtom NonemptyClassRangesNoDash /
  ClassAtom "-" ClassAtom ClassRanges
NonemptyClassRangesNoDash <- ClassAtom /
  ClassAtomNoDash NonemptyClassRangesNoDash /
  ClassAtomNoDash - ClassAtom /
  ClassRanges
ClassAtom <- "-" / ClassAtomNoDash
ClassAtomNoDash <- #TODO
ClassEscape <- "b" / "-" / CharacterClassEscape / CharacterEscape
"""
