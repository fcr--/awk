#!/usr/bin/awk -f

##
## PEG ENGINE
##

function peg_parse(GRAM, root, RES,     s, i, r, n) {
  s = ++peg_parse_stack
  i = RES["i"]
  r = peg_parse2(GRAM, root, RES)
  # If it was successful, add the remaining information to the resulting
  # concrete parsing tree:
  if (r) {
    tset(RES, RES["res"], "type", tget(GRAM, root, "type"))
    if (tisset(GRAM, root, "report"))
      tset(RES, RES["res"], "report", tget(GRAM, root, "report"))
    tset(RES, RES["res"], "start", i)
    tset(RES, RES["res"], "end", RES["i"])
  } else {
    if (i > RES["fail"])
      RES["fail"] = i
  }
  peg_parse_stack = s-1
  return r
}

function peg_parse2(GRAM, root, RES,     c, len, type, i, ch, CH, ch_count, s, rep) {
  type = tget(GRAM, root, "type")
  i = RES["i"]
  c = substr(RES["text"], i, 1)
  len = RES["len"]
  if (tisset(GRAM, root, "report"))
    rep = tget(GRAM, root, "report")

  ##for (c in GRAM) print "GRAM[" c "] = «" GRAM[c] "»"
  #for (s = 1; s < peg_parse_stack; s++) printf(" ")
  #print "    trying node "root" type "type" at "i (rep!=""?" reporting " rep:"")

  if (type == "string") {
    if (i > len)
      return 0
    s = tget(GRAM, root, "str")
    if (s == substr(RES["text"], i, length(s))) {
      RES["res"] = tnew(RES)
      RES["i"] += length(s)
      return 1
    }
    return 0
  } else if (type == "range") {
    if (i > len)
      return 0
    if ((tget(GRAM, root, "from") <= c) && (c <= tget(GRAM, root, "to"))) {
      RES["res"] = tnew(RES)
      RES["i"]++
      return 1
    }
    return 0
  } else if (type == "posla") {
    ch = tget(GRAM, root, "child")
    if (peg_parse(GRAM, ch, RES)) {
      rep = tnew(RES)
      tset(RES, rep, "children", RES["res"])
      RES["res"] = rep
      RES["i"] = i
      return 1
    }
    return 0
  } else if (type == "negla") {
    ch = tget(GRAM, root, "child")
    if (!peg_parse(GRAM, ch, RES)) {
      RES["res"] = tnew(RES)
      return 1
    }
    RES["i"] = i
    tdelres(RES, RES["res"])
    return 0
  } else if (type == "opt") {
    ch = tget(GRAM, root, "child")
    rep = tnew(RES)
    if (peg_parse(GRAM, ch, RES))
      tset(RES, rep, "children", RES["res"])
    RES["res"] = rep
    return 1
  } else if (type == "aster") {
    ch = tget(GRAM, root, "child")
    rep = tnew(RES)
    while (peg_parse(GRAM, ch, RES)) {
      if (tget(RES, rep, "children") != "")
	RES["res"] = " " RES["res"]
      tset(RES, rep, "children", tget(RES, rep, "children") RES["res"])
    }
    RES["res"] = rep
    return 1
  } else if (type == "plus") {
    ch = tget(GRAM, root, "child")
    if (!peg_parse(GRAM, ch, RES))
      return 0
    rep = tnew(RES)
    tset(RES, rep, "children", RES["res"])
    while (peg_parse(GRAM, ch, RES))
      tset(RES, rep, "children", tget(RES, rep, "children") " " RES["res"])
    RES["res"] = rep
    return 1
  } else if (type == "cat") {
    ch_count = split(tget(GRAM, root, "children"), CH, " ")
    for (ch = 1; ch <= ch_count; ch++) {
      if (!peg_parse(GRAM, CH[ch], RES)) {
	RES["i"] = i # roll back
	# destroy previous children
	while (--ch > 0)
	  tdelres(RES, CH[ch, "res"])
	return 0
      }
      # we need to store our children results:
      CH[ch, "res"] = RES["res"]
    }
    rep = tnew(RES)
    s = CH[1, "res"]
    for (ch = 2; ch <= ch_count; ch++)
      s = s " " CH[ch, "res"]
    RES["res"] = rep
    tset(RES, rep, "children", s)
    return 1
  } else if (type == "alt") {
    ch_count = split(tget(GRAM, root, "children"), CH, " ")
    for (ch = 1; ch <= ch_count; ch++) {
      if (peg_parse(GRAM, CH[ch], RES)) {
	rep = tnew(RES);
	tset(RES, rep, "children", RES["res"])
	RES["res"] = rep;
	return 1
      }
    }
    return 0
  } else if (type == "dot") {
    if (i > len)
      return 0
    RES["res"] = tnew(RES)
    RES["i"]++
    return 1
  } else {
    print "invalid type", type
    exit
  }
}

##
## GENERIC FUNCTIONS FOR GRAPHS (trees with cycles)
##

function tnew(T) {
  return ++T["ncount"]
}

function tset(T, n, k, v) {
  T[n, k] = v
}

function tget(T, n, k) {
  return T[n, k]
}

function tisset(T, n, k) {
  return ((n SUBSEP k) in T)
}

##
## HELPER FUNCTION FOR RAW PEG GRAMMAR CREATION:
##

function tpeg(GRAM, type, a1, a2, a3,     n) {
  n = tnew(GRAM)
  return tpeg_node(GRAM, n, type, a1, a2, a3)
}

function tpeg_node(GRAM, n, type, a1, a2, a3) {
  tset(GRAM, n, "type", type)
  # we change semantics of a1..a3 according to type:
  if (type == "string") {
    tset(GRAM, n, "str", a1)
  } else if (type == "range") {
    tset(GRAM, n, "from", a1)
    tset(GRAM, n, "to", a2)
  } else if (type == "posla") {
    tset(GRAM, n, "child", a1)
  } else if (type == "negla") {
    tset(GRAM, n, "child", a1)
  } else if (type == "opt") {
    tset(GRAM, n, "child", a1)
  } else if (type == "aster") {
    tset(GRAM, n, "child", a1)
  } else if (type == "plus") {
    tset(GRAM, n, "child", a1)
  } else if (type == "cat") {
    tset(GRAM, n, "children", a1)
  } else if (type == "alt") {
    tset(GRAM, n, "children", a1)
  } else if (type == "dot") {
    # no args
  } else {
    print "invalid type", type
    exit
  }
  return n
}

##
## FUNCTIONS FOR PROCESSING THE CONCRETE SYNTAX TREE
##

function tdelres(T, n,     drs, ch_count, ch, CH) {
  drs++
  if (drs>1000) {
    print n":", tget(T, n, "children")
    if (drs>1010) {
      print "stack overflow at tdelres"
      exit
    }
  }
  ch_count = split(tget(T, n, "children"), CH, " ")
  for (ch = 1; ch <= ch_count; ch++)
    tdelres(T, CH[ch], drs)
  delete T[n, "children"]
  delete T[n, "report"]
  delete T[n, "type"]
  delete T[n, "start"]
  delete T[n, "end"]
  delete T[n]
}

function tflattenres(T, n,     not_top, cs, ch_count, ch, CH) {
  if (tisset(T, n, "report") || !not_top) {
    ch_count = split(tget(T, n, "children"), CH, " ")
    for (ch = 1; ch <= ch_count; ch++)
      cs = cs " " tflattenres(T, CH[ch], 1)
    sub(/^ +/, "", cs)
    sub(/ +$/, "", cs)
    gsub(/  +$/, " ", cs)
    tset(T, n, "children", cs)
    return n
  } else {
    # return the list of children:
    ch_count = split(tget(T, n, "children"), CH, " ")
    for (ch = 1; ch <= ch_count; ch++)
      cs = cs " " tflattenres(T, CH[ch], 1)
    return cs
  }
}

function dump_res(RES, n, margin,     ch_count, ch, CH, r) {
  if (tisset(RES, n, "report"))
    r = " report=" tget(RES, n, "report")
  print margin "«"n"» type=" tget(RES, n, "type"), "start=" tget(RES, n, "start"), \
	"end=" tget(RES, n, "end") r ":"
  ch_count = split(tget(RES, n, "children"), CH, " ")
  for (ch = 1; ch <= ch_count; ch++)
    dump_res(RES, CH[ch], margin "  ")
}

##
## GRAMMAR FOR STANDARD PEG GRAMMAR!
##

function peg_peg_grammar(G,     n1, n2, n3,
	expr, alt, cat, la, negla, posla, cuant, cuantopt, cuantaster,
	cuantplus, atom, range, char, str, nt, dot, blanks, anychar) {
  expr = tnew(G)
  alt = tnew(G)
  cat = tnew(G)
  la = tnew(G)
  negla = tnew(G)
  posla = tnew(G)
  cuant = tnew(G)
  cuantopt = tnew(G)
  cuantaster = tnew(G)
  cuantplus = tnew(G)
  atom = tnew(G)
  range = tnew(G)
  char = tnew(G)
  str = tnew(G)
  nt = tnew(G)
  dot = tnew(G)
  blanks = tnew(G)
  anychar = tpeg(G, "dot")

  # expr = (blanks nt blanks '=' blanks alt ';')+ blanks !.
  n1 = tpeg(G, "plus", \
	tpeg(G, "cat", blanks " " nt " " blanks " " \
		tpeg(G, "string", "=") " " blanks " " alt " " \
		tpeg(G, "string", ";")))
  n2 = tpeg(G, "negla", anychar)
  
  tset(G, expr, "type", "cat")
  tset(G, expr, "children", n1 " " blanks " " n2)
  tset(G, expr, "report", "expr")

  # alt = cat blanks ('/' blanks cat blanks)*
  n1 = tnew(G)
  tset(G, n1, "type", "string")
  tset(G, n1, "str", "/")
  n2 = tnew(G)
  tset(G, n2, "type", "cat")
  tset(G, n2, "children", n1 " " blanks " " cat " " blanks)
  n3 = tnew(G)
  tset(G, n3, "type", "aster")
  tset(G, n3, "child", n2)

  tset(G, alt, "type", "cat")
  tset(G, alt, "children", cat " " blanks " " n3)
  tset(G, alt, "report", "alt")

  # cat = (la blanks)+; # use "" for epsilon productions
  n1 = tnew(G)
  tset(G, n1, "type", "cat")
  tset(G, n1, "children", la " " blanks)

  tset(G, cat, "type", "plus")
  tset(G, cat, "child", n1)
  tset(G, cat, "report", "cat")

  # la = negla / posla / cuant;
  tset(G, la, "type", "alt")
  tset(G, la, "children", negla " " posla " " cuant)
  # tset(G, la, "report", "la") # no need to report

  # negla = '!' blanks cuant;
  tset(G, negla, "type", "cat")
  tset(G, negla, "children", tpeg(G, "string", "!") " " blanks " " cuant)
  tset(G, negla, "report", "negla")

  # posla = '&' blanks cuant;
  tset(G, posla, "type", "cat")
  tset(G, posla, "children", tpeg(G, "string", "&") " " blanks " " cuant)
  tset(G, posla, "report", "posla")

  # cuant = atom blanks (cuantopt / cuantaster / cuantplus)?;
  n1 = tpeg(G, "opt", tpeg(G, "alt", cuantopt " " cuantaster " " cuantplus))

  tset(G, cuant, "type", "cat")
  tset(G, cuant, "children", atom " " blanks " " n1)
  tset(G, cuant, "report", "cuant")

  # cuantopt = '?';
  tset(G, cuantopt, "type", "string")
  tset(G, cuantopt, "str", "?")
  tset(G, cuantopt, "report", "cuantopt")

  # cuantaster = '*';
  tset(G, cuantaster, "type", "string")
  tset(G, cuantaster, "str", "*")
  tset(G, cuantaster, "report", "cuantaster")

  # cuantplus = '+';
  tset(G, cuantplus, "type", "string")
  tset(G, cuantplus, "str", "+")
  tset(G, cuantplus, "report", "cuantplus")

  # atom = range / char / str / nt / '(' alt ')' / dot;
  n1 = tpeg(G, "cat", tpeg(G, "string", "(") " " alt " " tpeg(G, "string", ")"))

  tset(G, atom, "type", "alt")
  tset(G, atom, "children", range " " char " " str " " nt " " n1 " " dot)
  # tset(G, atom, "report", "atom") # no need to report

  # range = char blanks ".." blanks char;
  n1 = tpeg(G, "string", "..")

  tset(G, range, "type", "cat")
  tset(G, range, "children", char " " blanks " " n1 " " blanks " " char)
  tset(G, range, "report", "range")

  # char = '\'' ('\\' . / .) '\'';
  n1 = tnew(G)
  tset(G, n1, "type", "string")
  tset(G, n1, "str", "\\")
  n2 = tnew(G)
  tset(G, n2, "type", "cat")
  tset(G, n2, "children", n1 " " anychar)
  n1 = tnew(G)
  tset(G, n1, "type", "alt")
  tset(G, n1, "children", n2 " " anychar)
  n2 = tnew(G)
  tset(G, n2, "type", "string")
  tset(G, n2, "str", "'")

  tset(G, char, "type", "cat")
  tset(G, char, "children", n2 " " n1 " " n2)
  tset(G, char, "report", "char")

  # str = '"' ('\\' . / !'"' .)* '"';
  n1 = tpeg(G, "string", "\"")

  n2 = tpeg(G, "aster", \
	tpeg(G, "alt", \
		tpeg(G, "cat", tpeg(G, "string", "\\") " " anychar) " " \
		tpeg(G, "cat", tpeg(G, "negla", n1) " " anychar)))

  tset(G, str, "type", "cat")
  tset(G, str, "children", n1 " " n2 " " n1)
  tset(G, str, "report", "str")

  # nt = ('A'..'Z' / 'a'..'z' / '_') ('A'..'Z' / 'a'..'z' / '_' / '0'..'9')*;
  n1 = tpeg(G, "range", "A", "Z") " " \
	tpeg(G, "range", "a", "z") " " \
	tpeg(G, "string", "_")
  n2 = tpeg(G, "aster", tpeg(G, "alt", n1 " " tpeg(G, "range", "0", "9")))
  n1 = tpeg(G, "alt", n1)

  tset(G, nt, "type", "cat")
  tset(G, nt, "children", n1 " " n2)
  tset(G, nt, "report", "nt")

  # dot = '.';
  tset(G, dot, "type", "string")
  tset(G, dot, "str", ".")
  tset(G, dot, "report", "dot")

  # blanks = (' ' / '\t' / '\n' / '\v' / '\f' / '\r' / '#' (!'\n' .)*)*;  # <- comments
  n1 = tpeg(G, "alt", 
	tpeg(G, "string", " ") " " \
	tpeg(G, "range", "\t", "\r") " " \
	tpeg(G, "cat",
		tpeg(G, "string", "#") " " \
		tpeg(G, "aster",
			tpeg(G, "cat",
				tpeg(G, "negla",
					tpeg(G, "string", "\n")) " " \
				anychar))))

  tset(G, blanks, "type", "aster")
  tset(G, blanks, "child", n1)
  #tset(G, blanks, "report", "blanks") # there's no need to report this.

  return expr
}

##
## CODE GENERATOR (FROM SYNTAX TREE)
##

function yapegic_gen(text, margin, RES, n, nname,
		     type, report, ch, CH, ch_count, attrs,
		     start, end, matched, t1, t2, res) {
  report = tget(RES, n, "report")
  start = tget(RES, n, "start")
  end = tget(RES, n, "end")
  matched = substr(text, start, end - start)
  ch_count = split(tget(RES, n, "children"), CH, " ")
  if (report == "expr") {
    res = "gen_grammar(G,     "
    for (ch = 1; ch <= ch_count; ch+=2) {
      t1 = yapegic_gen(text, margin"  ", RES, CH[ch])
      res = res (ch==1?"":", ") t1
      t2 = t2 margin t1 " = tnew()\n"
    }
    res = res ") {\n" t2
    for (ch = 1; ch <= ch_count; ch+=2) {
      t1 = yapegic_gen(text, margin"  ", RES, CH[ch])
      res = res margin yapegic_gen(text, margin"  ", RES, CH[ch+1], t1) "\n" \
	  margin "tset(G, " t1 ", \"report\", \"" t1 "\")\n"
    }
    res = res "}"
    return res
  } else if (report == "nt") {
    return matched
  }
  if (ch_count == 1 && (report == "alt" || report == "cat" || report == "cuant")) {
    return yapegic_gen(text, margin, RES, CH[1], nname)
  }
  if (report == "alt" || report == "cat" || report == "negla" || report == "posla") {
    attrs = ", \\\n"
    for (ch = 1; ch <= ch_count; ch++) {
      attrs = attrs margin yapegic_gen(text, margin"  ", RES, CH[ch]) \
	    (ch < ch_count ? " \" \" \\\n" : "")
    }
  } else if (report == "cuant") {
    if (tget(RES, CH[2], "report") == "cuantopt") {
      report = "opt"
    } else if (tget(RES, CH[2], "report") == "cuantaster") {
      report = "aster"
    } else if (tget(RES, CH[2], "report") == "cuantplus") {
      report = "plus"
    }
    attrs = ", \\\n" margin yapegic_gen(text, margin"  ", RES, CH[1])
  } else if (report == "range") {
    start = tget(RES, CH[1], "start")
    end = tget(RES, CH[1], "end")
    t1 = substr(text, start + 1, end - start - 2)
    sub(/\\'/, "'", t1)
    sub(/"/, "\\\"", t1)
    start = tget(RES, CH[2], "start")
    end = tget(RES, CH[2], "end")
    t2 = substr(text, start + 1, end - start - 2)
    sub(/\\'/, "'", t2)
    sub(/"/, "\\\"", t2)
    attrs = ", \"" t1 "\", \"" t2 "\""
  } else if (report == "char") {
    report = "string"
    matched = substr(matched, 2, 1)
    sub(/\\'/, "'", matched)
    sub(/"/, "\\\"", matched)
    attrs = ", \"" matched "\""
  } else if (report == "str") {
    report = "string"
    attrs = ", " matched
  }
  if (nname != "") {
    return "tpeg_node(G, " nname ", \"" report "\"" attrs ")"
  } else {
    return "tpeg(G, \"" report "\"" attrs ")"
  }
}

function yapegic(text,     G, RES, esc) {
  RES["text"] = text; RES["i"] = 1; RES["len"] = length(text)
  expr = peg_peg_grammar(G)
  if (peg_parse(G, expr, RES)) {
    # print "matched, cursor left at", RES["i"] # useless in most cases
    #for (token in RES) print "RES[" token "] = «" RES[token] "»"

    ## Uncomment the following line if you want to display the concrete
    ## syntax tree:
    #dump_res(RES, RES["res"])

    tflattenres(RES, RES["res"])

    ## Uncomment the following lines if you want to display the simplified
    ## syntax tree, when non-reporting nodes are deleted:
    #print "FLATTENED AST:"
    #dump_res(RES, RES["res"])

    # Just call the generator:
    return yapegic_gen(text, "  ", RES, RES["res"])

  } else {
    esc = sprintf("%c", 27)
    print "failed at char", RES["fail"] ":\n\n" \
	substr(text, 1, RES["fail"]-1) esc "[7m" \
	substr(text, RES["fail"], 1) esc "[0m" \
	substr(text, RES["fail"]+1)
    return ""
  }
}

##
## EXAMPLE: VERBOSE GRAMMAR EQUIVALENT TO REGEXP /^[0-9]+$/
##

# BEGIN {
#   # "('0'..'9')+ !."
#   n1 = tnew(G1)
#   tset(G1, n1, "type", "range")
#   tset(G1, n1, "from", "0")
#   tset(G1, n1, "to", "9")
#   n2 = tnew(G1)
#   tset(G1, n2, "type", "plus")
#   tset(G1, n2, "child", n1)
#   n3 = tnew(G1)
#   tset(G1, n3, "type", "dot")
#   n4 = tnew(G1)
#   tset(G1, n4, "type", "negla")
#   tset(G1, n4, "child", n3)
#   n5 = tnew(G1)
#   tset(G1, n5, "type", "cat")
#   tset(G1, n5, "children", n2 " " n4)
# }
# or the ultra short alternative:
# BEGIN { print yapegic("decimal = ('0'..'9')+ !.;"); exit }

{ s = s $0 "\n" }

END { if (s!="") print yapegic(s) }
