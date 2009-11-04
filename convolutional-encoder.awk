#!/usr/bin/awk -f
#
# convolutional-encoder: A software encoder for convolutional codes.
# Copyright (C) 2009  Francisco Castro <fcr@adinet.com.uy>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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

# 7/5 = (1+D+D^2)/(1+D^2)
function G_to_circuit(p, q,     c, deg, i, bit0) {
  deg = int(log(p<q ? p : q)/log(2))
  for (i=2; i<=deg; i++) {
    c = c "/d"(i-1)" rcl /d"i" sto "
  }
  c = c "/d input dup out"
  for (i=1; i<=deg; i++) {
    q = int(q / 2)
    if (int(q % 2))
      c = c " /d"i" rcl xor"
  }
  bit0 = ""
  if (int(p % 2)) {
    c = c " dup"
    bit0 = " xor"
  }
  c = c " /d1 sto"
  for (i=1; i<=deg; i++) {
    p = int(p / 2)
    if (int(p % 2)) {
      c = c " /d"i" rcl" bit0
      bit0 = " xor"
    }
  }
  c = c " out"
  return c
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
	  "/d input out"
  # Coding Theory: The essentials - D.G Hoffman
  hoffman_sr_1 = "/d input /X0 sto " \
	  "/X0 rcl /X1 sto " \
	  "/X1 rcl /X2 sto " \
	  "/X2 rcl /X3 sto " \
	  "/X0 rcl /X1 rcl xor /X3 rcl xor out"
  hoffman_fsr_1 = "/d input /X2 rcl xor /X0 sto " \
	  "/X0 rcl /X2 rcl xor /X1 sto " \
	  "/X1 rcl /X2 sto " \
	  "/X2 rcl out"
  # Other binary recursive systematic codes given by their rational
  # functions written with two numbers whose coefficients are their
  # binary representation:
  #circuit = G_to_circuit(021, 037)
  #circuit = G_to_circuit(01, 013)
  circuit = G_to_circuit(07, 05)
  print "Circuit:", circuit
}

{
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
