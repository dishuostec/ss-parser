{
  const makeInteger = (int) => parseInt(int.join(""), 10);

  const starminmax = (min, max) => {
    min = parseInt(min, 10);
    max = parseInt(max, 10);
    if (min === 0) {
      if (max > 1) {
        return `\\s*((?:\\S+\\s+){0,${max - 1}}\\S+)?\\s*`;
      } else {
        return `\\s*(\\S+)?\\s*`;
      }
    } if (min === max) {
      if (min === 1) {
        return `\\s*(\\S+)\\s*`;
      } else {
        return `\\s*((?:\\S+\\s+){${min - 1}}\\S+)\\s*`;
      }
    } else {
      return `\\s*((?:\\S+\\s+){${min - 1},${max - 1}}\\S+)\\s*`;
    }
  }
}

start
  = trigger

star
  = "*" { return { raw: "*", clean: "(?:(?=^|\\s)\\s*(?:.*)(?=\\s|$)\\s*)?" }; }
  / "(" ws* "*" ws* ")" { return { raw: "(*)", clean: "(?=^|\\s)\\s*(.*)(?=\\s|$)\\s*" }; }

// As far as I can tell: * and [*] are equivalent and can be empty, while (*) cannot
// match to an empty string.

starn
  = "*" val:integer { return { raw: `*${val}`, clean: starminmax(val, val) }; }
  / "*(" val:integer ")" { return { raw: `*(${val})`, clean: starminmax(val, val) }; }

starupton
  = "*~" val:integer { return { raw: `*~${val}`, clean: starminmax(0, val) }; }

starminmax
  = "*(" ws* min:integer ws* "," ws* max:integer ws* ")"
    { return { raw: `*(${min},${max})`, clean: starminmax(min, max) }; }
  / "*(" ws* min:integer ws* "-" ws* max:integer ws* ")"
    { return { raw: `*(${min},${max})`, clean: starminmax(min, max) }; }

string
  = str:[a-zA-Z\u4E00-\u9FA5]+ { return { type: "string", val: str.join("")}; }

cleanedString
  = wsl:ws* string:[^|()\[\]\n\r*]+ wsr:ws* { return string.join(""); }

alternates
  = "(" alternate:cleanedString alternates:("|" cleanedString:cleanedString { return cleanedString; } )+ ")"
    {
      const cleaned = [alternate].concat(alternates).join("|");
      return {
        raw: `(${cleaned})`,
        clean: `(?=^|\\s)\\s*(${cleaned})(?=\\s|$)\\s*`
      };
    }

optionals
  = "[" optional:cleanedString optionals:("|" cleanedString:cleanedString { return cleanedString; } )* "]"
    {
      const cleaned = [optional].concat(optionals).join("|");
      return {
        raw: `[${cleaned}]`,
        clean: `(?:(?:\\s+|\\b|^)(?:${cleaned}(?:\\s|\\b|$))?)?`,
      };
    }
  / "[" ws* "*" ws* "]"
    {
      return {
        raw: "[*]",
        clean: "(?:(?:\\s|\\b|^)(?:.*(?:\\s|\\b|$))?)?",
      };
    }

EOF
  = !.

triggerTokens
  = wsl:ws* alternates:alternates wsr:ws*
    { return { raw: `${wsl.join("")}${alternates.raw}${wsr.join("")}`, clean: alternates.clean } }
  / wsl:ws* optionals:optionals wsr:ws*
    { return { raw: `${wsl.join("")}${optionals.raw}${wsr.join("")}`, clean: optionals.clean } }
  / wsl:ws* starn:starn wsr:ws*
    { return { raw: `${wsl.join("")}${starn.raw}${wsr.join("")}`, clean: starn.clean }; }
  / wsl:ws* starupton:starupton wsr:ws*
    { return { raw: `${wsl.join("")}${starupton.raw}${wsr.join("")}`, clean: starupton.clean }; }
  / wsl:ws* starminmax:starminmax wsr:ws*
    { return { raw: `${wsl.join("")}${starminmax.raw}${wsr.join("")}`, clean: starminmax.clean }; }
  / wsl:ws* star:star wsr:ws*
    { return { raw: `${wsl.join("")}${star.raw}${wsr.join("")}`, clean: star.clean }; }
  / string:escapedCharacter+
    { return { raw: string.join(""), clean: `${string.join("")}` };}
  / ws:ws
    { return { raw: ws, clean: ws }; }

trigger
  = tokens:triggerTokens*
    {
      return {
        raw: tokens.map((token) => token.raw).join(""),
        clean: tokens.map((token) => token.clean).join("")
      };
    }

escapedCharacter
  = "\\" character:[*~?\[\]\(\)]
    { return `\\${character}`; }
  / character:[+?*]
    { return `\\${character}`; }
  / character:[^*\n\r \t]
    { return character; }

integer "integer"
  = digits:[0-9]+ { return makeInteger(digits); }

ws "whitespace" = [ \t]

nl "newline" = [\n\r]
