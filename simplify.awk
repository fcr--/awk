#!/usr/bin/awk -f

# Use with expressions like: x' y z' + y' z'

function analyze(expr, E,     res, LE, VARS, vars, i, c, k, lv, nv) {
  for (i=1; i<=length(expr); i++) {
    c = substr(expr, i, 1)
    if (c ~ /[a-z]/) {
      VARS[c] = 1 # The variable exists:
      LE[c]=1
      lv = c
      nv++
    } else if (c == "'") {
      if (lv == "")
	return ("Syntax error at char " i ": Negate is a postorder operator.")
      LE[lv] = 1-LE[lv]
    } else if(c == "+") {
      if (!nv)
	return ("Syntax error at char " i ": Incorrectly placed + operator.")
      E["count"]++
      for (k in LE)
	E[E["count"], k] = LE[k]
      nv = 0
      split("", LE) # Clear array LE.
    } else if (c ~ /[[:space:]]/) {
    } else
      return ("Syntax error at char " i ": Invalid character.")
  }
  if (!nv)
    return ("Syntax error at char " i ": + at end of expression.")
  E["count"]++
  for (k in LE)
    E[E["count"], k] = LE[k]
  nv = 0
  for (k in VARS) {
    vars = vars " " k
    nv++
  }
  sub(/^ /, "", vars)
  E["vars"] = vars
  return ("OK: " nv " vars: " vars ".")
}

function evaluate(E, V,     i, EXPR, k, K) {
  for (i=1; i<=E["count"]; i++) {
    EXPR[i]=1
  }
  for (k in E) {
    if (2 == split(k, K, SUBSEP)) {
      EXPR[K[1]] *= V[K[2]] == E[k]
#      print "(e: "K[1]", "K[2]")"
    }
  }
  for (i=1; i<=E["count"]; i++) {
    if (EXPR[i])
      return 1
  }
  return 0
}

function print_truth_table(E,     i, VARS, V, nv, n) {
  nv = split(E["vars"], VARS, " ")
  for (i=1; i<=nv; i++) {
    V[VARS[i]] = 0
  }
  print E["vars"], "="
  while (1) {
    for (i=1; i<=nv; i++) {
      printf("%d ", V[VARS[i]])
    }
    print evaluate(E, V)
    i = nv
    do {
      if (!i) return
      V[VARS[i]] = 1 - V[VARS[i]]
    } while(V[VARS[i--]] == 0)
  }
}

function delete_term(E, i,     k, K, T) {
  for (k in E) {
    if (2 == split(k, K, SUBSEP) && K[1]>=i) {
      if (K[1] > i)
	T[K[1]-1, K[2]] = E[k]
      delete E[k]
    }
  }
  for (k in T)
    E[k] = T[k]
}

{
  # Clear array E:
  split("", E)
  # Parse the expression:
  print analyze($0, E)
  # May not be needed in future, but it's useful for debugging purposes:
  print_truth_table(E)
}
