#!/usr/bin/awk -f
function pop(STK, expected_type,    type, val) {
  if (!("n" in STK) || STK["n"]<1) {
    print "Warning: stack underflow."
    type = "null pointer"
    val = "(null)"
  } else {
    type = STK["type",STK["n"]]
    val = STK["val",STK["n"]]
    STK["n"]--
  }
  if (type != expected_type)
    print "Warning: unexpected type: " type ", waiting for: " expected_type "."
  return val
}

function push(STK, type, val) {
  STK["type",++STK["n"]] = type
  STK["val",STK["n"]] = val
}

function dup(STK) {
  if (!("n" in STK) || STK["n"]<1) {
    print "Warning: stack underflow."
    type = "null pointer"
    val = "(null)"
  } else {
    STK["type",1+STK["n"]] = STK["type",STK["n"]]
    STK["val",1+STK["n"]] = STK["val",STK["n"]]
    STK["n"]++
  }
}

function dump(STK,     i, res) {
  for (i=1; i<=STK["n"]; i++)
    res = res " {" STK["type", i] ": " STK["val", i] "}"
  return res
}

function run_step(circuit, INP, STATES,    i, tmp, OP, n, STK, iter, res) {
  n = split(circuit, OP, " +")
  iter = STATES["iter"] = !STATES["iter"]
  for (i=1; i<=n; i++) {
    #print "Debug: opcode «" OP[i] "» stk" dump(STK)
    if (OP[i]=="out") {
      res = res pop(STK, "bool") " "
    } else if (OP[i]=="xor") {
      push(STK, "bool", (pop(STK, "bool")!=pop(STK, "bool")))
    } else if (OP[i]=="not") {
      push(STK, "bool", !pop(STK, "bool"))
    } else if (OP[i]=="rcl") {
      tmp = STATES[pop(STK, "name"), !iter]
      if (tmp == "") tmp = 0
      push(STK, "bool", tmp)
    } else if (OP[i]=="input") {
      tmp=pop(STK, "name")
      if (!(tmp in INP)) {
	print "Warning: input " tmp " not defined."
       	tmp = 0
      } else {
	tmp = INP[tmp]
	if (tmp !~ /^[01]$/) {
	  print "Warning: input value not boolean, using 0."
	  tmp = 0
	}
      }
      push(STK, "bool", tmp)
    } else if (OP[i]=="sto") {
      tmp = pop(STK, "name")
      STATES[tmp, iter] = pop(STK, "bool")
    } else if (OP[i] ~ /^[01]$/) {
      push(STK, "bool", OP[i])
    } else if (OP[i] ~ /^\//) {
      push(STK, "name", OP[i])
    } else if (OP[i] == "dup") {
      dup(STK)
    }
  }
  sub(/ $/, "", res)
  return res
}

BEGIN {
# The ten-year-old turbo codes are entering into service:
# http://www-elec.enst-bretagne.fr/equipe/berrou/com_mag_berrou.pdf
nrnsc_a = "/d input /d1 sto " \
	"/d1 rcl /d2 sto " \
	"/d2 rcl /d3 sto " \
	"/d input /d1 rcl xor /d3 rcl xor out " \
	"/d input /d2 rcl xor /d3 rcl xor out"
rsc_b = "/d input dup out " \
	"/a1 rcl xor /a3 rcl xor dup /a1 sto " \
	"/a2 rcl xor /a3 rcl xor out " \
	"/a1 rcl /a2 sto " \
	"/a2 rcl /a3 sto"
# http://en.wikipedia.org/wiki/File:Convolutional_encoder.png
nrnsc_1 = "/d input /m1 sto " \
	"/m1 rcl /m0 sto " \
	"/m0 rcl /m1 sto " \
	"/m1 rcl /m0 rcl /m-1 rcl xor xor out " \
	"/m0 rcl /m-1 rcl xor out " \
	"/m1 rcl /m-1 rcl xor out"
# http://en.wikipedia.org/wiki/File:Convolutional_encoder_recursive.svg
rsc_2 = "/r1 rcl /r2 sto " \
	"/r2 rcl /r3 sto " \
	"/d input /r2 rcl /r3 rcl xor xor dup /r1 sto " \
	"/r1 rcl xor /r3 xor out " \
	"/d input out "
}

{
  circuit = rsc_b
  for (i=1; i<=NF; i++) {
    INPUT["/d"] = $i
    print run_step(circuit, INPUT, Q)
  }
}

END {
  INPUT["/d"] = 0
  # print "---"
  # print run_step(circuit, INPUT, Q)
  # print run_step(circuit, INPUT, Q)
  # print run_step(circuit, INPUT, Q)
}
