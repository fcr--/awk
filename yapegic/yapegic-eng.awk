##
## PEG ENGINE
##

function peg_parse(GRAM, root, RES,     s, i, r, n) {
  #s = ++peg_parse_stack
  i = RES["i"]
  r = peg_parse2(GRAM, root, RES)
  # If it was successful, add the remaining information to the resulting
  # concrete parsing tree:
  if (r) {
    if (tisset(GRAM, root, "report")) {
      tset(RES, RES["res"], "type", tget(GRAM, root, "type"))
      tset(RES, RES["res"], "start", i)
      tset(RES, RES["res"], "end", RES["i"])
      tset(RES, RES["res"], "report", tget(GRAM, root, "report"))
      # Running early tflattenres is an important memory optimization.
      # you may disable this if you really need the unflattened tree.
      tflattenres(RES, RES["res"])
    }
  } else {
    if (i > RES["fail"])
      RES["fail"] = i
  }
  #peg_parse_stack = s-1
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
    tdelres(RES, RES["res"]) #@delete_on_simplify
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
	while (--ch > 0) #@delete_on_simplify
	  tdelres(RES, CH[ch, "res"]) #@delete_on_simplify
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

function tpeg(G, type, a1, a2,     n) {
  n = tnew(G)
  return tpeg_node(G, n, type, a1, a2)
}

function tpeg_node(G, n, type, a1, a2) {
  tset(G, n, "type", type)
  # we change semantics of a1..a3 according to type:
  if (type == "string") {
    tset(G, n, "str", a1)
  } else if (type == "range") {
    tset(G, n, "from", a1)
    tset(G, n, "to", a2)
  } else if (type == "posla" || type == "negla" || \
	 type == "opt" || type == "aster" || type == "plus") {
    tset(G, n, "child", a1)
  } else if (type == "cat" || type == "alt") {
    tset(G, n, "children", a1)
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

#@begin_delete_on_simplify
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
}
#@end_delete_on_simplify

function tflattenres(T, n,     not_top, cs, ch_count, ch, CH) {
  if (tisset(T, n, "report") || !not_top) {
    ch_count = split(tget(T, n, "children"), CH, " ")
    for (ch = 1; ch <= ch_count; ch++)
      cs = cs " " tflattenres(T, CH[ch], 1)
    sub(/^ +/, "", cs)
    sub(/ +$/, "", cs)
    gsub(/  +/, " ", cs)
    tset(T, n, "children", cs)
    return n
  } else {
    # return the list of children:
    ch_count = split(tget(T, n, "children"), CH, " ")
    for (ch = 1; ch <= ch_count; ch++)
      cs = cs " " tflattenres(T, CH[ch], 1)
    delete T[n, "children"]
    return cs
  }
}

#@begin_delete_on_simplify
function dump_res(RES, n, margin,     ch_count, ch, CH, r) {
  if (tisset(RES, n, "report"))
    r = " report=" tget(RES, n, "report")
  print margin "«"n"» type=" tget(RES, n, "type"), "start=" tget(RES, n, "start"), \
	"end=" tget(RES, n, "end") r ":"
  ch_count = split(tget(RES, n, "children"), CH, " ")
  for (ch = 1; ch <= ch_count; ch++)
    dump_res(RES, CH[ch], margin "  ")
}
#@end_delete_on_simplify

function print_error_res(RES,     esc) {
  esc = sprintf("%c", 27)
  print "failed at char", RES["fail"] ":\n\n" \
      substr(RES["text"], 1, RES["fail"]-1) esc "[7m" \
      substr(RES["text"], RES["fail"], 1) esc "[0m" \
      substr(RES["text"], RES["fail"]+1)
}
