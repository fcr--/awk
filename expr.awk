#!/usr/bin/awk -f

BEGIN {
  ord[""] = 0
  ord["+"] = ord["-"] = 1
  ord["*"] = ord["/"] = 2
  ord["neg"] = 3
  ord["^"] = 4
}

function top(s) {
  return s[s["c"]]
}
function pop(s) {
  if (s["c"])
    return s[s["c"]--]
  return
}
function push(s, e) {
  s[++s["c"]] = e
}
function get(s, pos) {
  return s[pos]
}

function parse_expr(text, fifo,
	i, stack, d, n, last, count, A, paren, item) {
  d = n = 0
  gsub(/ */, " ", text)
  sub(/^ */, "", text)
  # the extra spaces at end of expression are not cleared
  count = split(text, A, / */)
  last = "nothing"
  paren = 0
  for (i=1; i<=count; i++){
    if (A[i] ~ /[0-9]/) {
      if (d) {
	n += A[i]*m
	m /= 10
      } else
      	n = n*10+A[i]
      last = "num"
    } else if (A[i] ~ /[\.,]/) {
      d = 1
      m = .1
      last = "num"
    } else if (A[i] == "(") {
      paren++
      if (last == "expr" || last == "num") {
	print "unexpected open parenthesis"
	return 0
      }
      push(stack, "")
      last = "nothing"
    } else if (A[i] == ")") {
      if (last == "oper") {
	print "unexpected close parenthesis"
	return 0
      }
      if (!paren--) {
	print "unmatched close parenthesis"
	return 0
      }
      if (last == "num")
	push(fifo, n)
      while ((item = pop(stack)) != "")
	push(fifo, item)
      last = "expr"
    } else {
      if (last == "nothing" || last == "oper") {
	if (A[i] == "-") {
	  A[i] = "neg"
	} else {
	  print "unexpected operator " A[i] " at i=" i
	  return 0
	}
      } else if (last == "num")
	push(fifo, n)
      d = n = 0
      while (ord[A[i]] <= ord[top(stack)] && top(stack) != "") {
	push(fifo, pop(stack))
      }
      push(stack, A[i])
      last = "oper"
    }
  }
  push(fifo, "p")
  return 1
}

function eval_expr(fifo,
	i, n, x, y, rpn) {
  for (i=1; (n = get(fifo, i))!=""; i++) {
    if (n ~ /[0-9]/) { push(rpn, n) }
    else if (n == "+") { push(rpn, pop(rpn)+pop(rpn)) }
    else if (n == "neg") { push(rpn, -pop(rpn)) }
    else if (n == "*") { push(rpn, pop(rpn)*pop(rpn)) }
    else if (n == "-") { x = pop(rpn); y = pop(rpn); push(rpn, y-x) }
    else if (n == "/") {
      x=pop(rpn)
      if (x == 0) {
	print "division by 0"
	return 0
      }
      y=pop(rpn)
      push(rpn, y / x)
    }
    else if (n == "^") {
      x=pop(rpn)
      y=pop(rpn)
      if (y==0 && x<0) {
	print "division by 0"
	return 0
      }
      if (y<0 && int(x)!=x) {
	print "can't calculate negative roots"
	return 0
      }
      push(rpn, y^x)
    }
    else if (n == "p") { return top(rpn) }
  }
  return 0
}

function dump_stack(stack,   i) {
  for (i=1; i in stack; i++)
    print "\t" i ": " stack[i]
  if ((i+1) in stack)
    print "\tbroken stack: i+1 = " stack[i+1]
}

{
  for (i in fifo) delete fifo[i]
  parse_expr($0, fifo)
  dump_stack(fifo)
  print eval_expr(fifo)
}
