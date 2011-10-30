function parse(text,     G, RES) {
  RES["text"] = text; RES["i"] = 1; RES["len"] = length(text)
  if (peg_parse(G, gen_grammar(G), RES)) {
    #dump_res(RES, RES["res"])
    print eval(RES, RES["res"])
  } else {
    print_error_res(RES)
  }
}

function eval(RES, n,     t, rep, ch, CH, ch_count, t2) {
  t = substr(RES["text"], tget(RES, n, "start"), tget(RES, n, "end") - tget(RES, n, "start"))
  rep = tget(RES, n, "report")
  if (rep == "number") {
    return t
  } else if (rep == "expr" || rep == "summand") {
    # process the children list:
    ch_count = split(tget(RES, n, "children"), CH, " ")
    # evaluate the first child:
    t = eval(RES, CH[1])
    # for each pair of children:
    for (ch = 2; ch <= ch_count; ch+=2) {
      # get the reported operator of the former child:
      rep = tget(RES, CH[ch], "report")
      # and evaluate the latter child:
      t2 = eval(RES, CH[ch+1])
      # then calculate:
      if (rep == "opplus") {
	t = t + t2
      } else if (rep == "opminus") {
        t = t - t2
      } else if (rep == "opmult") {
        t = t * t2
      } else if (rep == "opdiv") {
        t = t / t2
      }
    }
    return t
  }
  return t
}

{ parse($0) }
