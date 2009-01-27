#!/usr/bin/awk -f

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

# returns the precedence order:
function ord(operator) {
  if (operator == "") return 0
  if (operator == ",") return 10
  if (operator ~ /^[+-]$/) return 20
  if (operator ~ /^[*\/]$/) return 30
  if (operator == "^") return 40
  if (operator ~ /^fn-/) return 50
}

function functions(fn, argc, argv) {
  if (fn == "fn-neg") {
    if (argc != 1) return "too many params"
    argv["res"] = -argv[1]
  } else if (fn == "fn-cos") {
    if (argc != 1) return "too many params"
    argv["res"] = cos(argv[1])
  } else if (fn == "fn-sin") {
    if (argc != 1) return "too many params"
    argv["res"] = sin(argv[1])
  } else {
    return "invalid function"
  }
}

# Specifies when right to left evaluation needed:
function rtl_evaluation_needed(pre, post) {
  # a^b^c case:
  if (pre == "^" && post == "^")
    return 1
  # a---b and -a^b cases:
  if (pre == "fn-neg")
    if (post == "fn-neg" || post == "^")
      return 1
  return 0
}

function parse_expr(text, fifo,
	i, stack, d, n, s, last, count, A, paren, item) {
  d = n = 0
  gsub(/ */, " ", text)
  sub(/^ */, "", text)
  # the extra spaces at end of expression are not cleared
  count = split(text, A, / */)
  last = "nothing"
  paren = 0
  s = ""
  for (i=1; i<=count; i++){
    if (A[i] ~ /[a-zA-Z_]/ || last == "string" && A[i] ~ /[0-9]/) {
      s = s A[i]
      last = "string"
    } else if (A[i] ~ /[0-9]/) {
      if (d) {
	n += A[i]*m
	m /= 10
      } else
      	n = n*10+A[i]
      last = "num"
    } else if (A[i] == ".") {
      if (last == "string") {
	print "\".\" not valid in this context"
	return 0
      }
      d = 1
      m = .1
      last = "num"
    } else if (A[i] == "(") {
      paren++
      if (last == "expr" || last == "num") {
	print "unexpected open parenthesis"
	return 0
      }
      if (last == "string") {
	push(stack, "fn-" s)
	s = ""
      }
      push(stack, "")
      last = "nothing"
    } else if (A[i] == ")") {
      if (last == "oper" || last == "string") {
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
      if (last == "nothing" || last == "oper" || last == "string") {
	if (A[i] == "-") {
	  A[i] = "fn-neg"
	} else {
	  print "unexpected operator " A[i] " at i=" i
	  return 0
	}
      } else if (last == "num")
	push(fifo, n)
      d = n = 0
      # In the while we pop from the operand stack (and append in the fifo)
      # the operands whose precedence orders are greater or equal than the
      # operand being actualy parsed, A[i].
      # We process the equal precendence case to keep the size of the
      # eval_expr's rpn stack at its minimum posible size: For example see the
      # 1+2+3 case and its two rpn representations: 1 2 3 + +, and 1 2 + 3 +,
      # we use the latter, unless right to left evaluation is needed:
      while (ord(A[i]) <= ord(top(stack)) && top(stack) != "" \
	     && !rtl_evaluation_needed(top(stack), A[i])) {
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
	i, n, x, y, res, count, rpn) {
  for (i=1; (n=get(fifo, i)) != ""; i++) {
    if (n ~ /[0-9]/) { push(rpn, n) }
    else if (n == "+") { push(rpn, pop(rpn)+pop(rpn)) }
    else if (n == "*") { push(rpn, pop(rpn)*pop(rpn)) }
    else if (n == "-") { x = pop(rpn); y = pop(rpn); push(rpn, y-x) }
    else if (n == "/") {
      x = pop(rpn)
      if (x == 0) {
	print "division by 0"
	return
      }
      y = pop(rpn)
      push(rpn, y / x)
    }
    else if (n == "^") {
      x = pop(rpn)
      y = pop(rpn)
      if (y==0 && x<0) {
	print "division by 0"
	return
      }
      if (y<0 && int(x)!=x) {
	print "can't calculate negative roots"
	return
      }
      push(rpn, y^x)
    }
    else if (n ~ /^fn-/) {
      count = split(pop(rpn), args, ";")
      res = functions(n, count, args)
      if (res != "") {
	print res
	return
      }
      if ("res" in args)
	push(rpn, args["res"])
    }
    else if (n == ",") {
      x = pop(rpn)
      y = pop(rpn)
      push(rpn, y ";" x)
    }
    else if (n == "p")
      return top(rpn)
    else {
      print "invalid operator " n
      return
    }
  }
  return
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
