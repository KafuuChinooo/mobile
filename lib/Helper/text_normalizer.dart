String normalizeText(String input) {
  const accentMap = <String, String>{
    // a
    "\u00e1": "a",
    "\u00e0": "a",
    "\u1ea3": "a",
    "\u00e3": "a",
    "\u1ea1": "a",
    "\u0103": "a",
    "\u1eaf": "a",
    "\u1eb1": "a",
    "\u1eb3": "a",
    "\u1eb5": "a",
    "\u1eb7": "a",
    "\u00e2": "a",
    "\u1ea5": "a",
    "\u1ea7": "a",
    "\u1ea9": "a",
    "\u1eab": "a",
    "\u1ead": "a",
    // d
    "\u0111": "d",
    // e
    "\u00e9": "e",
    "\u00e8": "e",
    "\u1ebb": "e",
    "\u1ebd": "e",
    "\u1eb9": "e",
    "\u00ea": "e",
    "\u1ebf": "e",
    "\u1ec1": "e",
    "\u1ec3": "e",
    "\u1ec5": "e",
    "\u1ec7": "e",
    // i
    "\u00ed": "i",
    "\u00ec": "i",
    "\u1ec9": "i",
    "\u0129": "i",
    "\u1ecb": "i",
    // o
    "\u00f3": "o",
    "\u00f2": "o",
    "\u1ecf": "o",
    "\u00f5": "o",
    "\u1ecd": "o",
    "\u00f4": "o",
    "\u1ed1": "o",
    "\u1ed3": "o",
    "\u1ed5": "o",
    "\u1ed7": "o",
    "\u1ed9": "o",
    "\u01a1": "o",
    "\u1edb": "o",
    "\u1edd": "o",
    "\u1edf": "o",
    "\u1ee1": "o",
    "\u1ee3": "o",
    // u
    "\u00fa": "u",
    "\u00f9": "u",
    "\u1ee7": "u",
    "\u0169": "u",
    "\u1ee5": "u",
    "\u01b0": "u",
    "\u1ee9": "u",
    "\u1eeb": "u",
    "\u1eed": "u",
    "\u1eef": "u",
    "\u1ef1": "u",
    // y
    "\u00fd": "y",
    "\u1ef3": "y",
    "\u1ef7": "y",
    "\u1ef9": "y",
    "\u1ef5": "y",
  };

  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune).toLowerCase();
    buffer.write(accentMap[char] ?? char);
  }
  return buffer.toString();
}
