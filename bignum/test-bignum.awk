# To run it:
#   for a short test: awk -f bignum.awk -f test-bignum.awk
#   for a long test: awk -f bignum.awk -f test-bignum.awk -v LONG=1

function ok(expr){
  if(expr)
    return "[32m" "ok" "[0m"
  return "[31m" "failed" "[0m"
}

function test_fromstr(){
  return ok(bignum_fromstr("2") == "bignum 0 2") \
    ", " ok(bignum_fromstr("-2") == "bignum 1 2") \
    ", " ok(bignum_fromstr("1000") == "bignum 0 1000") \
    ", " ok(bignum_fromstr("65536") == "bignum 0 0 1")
}

function test_add(){
  return ok(bignum_add("bignum 0 0", "bignum 0 0") == "bignum 0 0") \
    ", " ok(bignum_add("bignum 0 1", "bignum 0 1") == "bignum 0 2") \
    ", " ok(bignum_add("bignum 1 1", "bignum 0 1") == "bignum 0 0") \
    ", " ok(bignum_add("bignum 0 1", "bignum 1 1") == "bignum 0 0") \
    "; " ok(bignum_add("bignum 0 0 1", "bignum 1 0 1") == "bignum 0 0") \
    ", " ok(bignum_add("bignum 0 0 1", "bignum 1 0 1") == "bignum 0 0") \
    ", " ok(bignum_add("bignum 0 1 1", "bignum 0 1 1") == "bignum 0 2 2") \
    ", " ok(bignum_add("bignum 0 1 1", "bignum 1 1") == "bignum 0 0 1")
}

function test_mul(){
  return ok(bignum_mul("bignum 0 1", "bignum 0 63 82") == "bignum 0 63 82") \
    ", " ok(bignum_mul("bignum 0 0", "bignum 0 63 82") == "bignum 0 0") \
    ", " ok(bignum_mul("bignum 0 2", "bignum 0 2") == "bignum 0 4") \
    ", " ok(bignum_mul("bignum 0 2", "bignum 0 32768") == "bignum 0 0 1") \
    ", " ok(bignum_mul("bignum 0 3", "bignum 0 32768") == "bignum 0 32768 1") \
    ", " ok(bignum_mul("bignum 0 999", "bignum 0 999") == "bignum 0 14961 15")
}

function test_powers_of_two(n2, i, s){
  l = m = s = n2 = bignum_fromstr("2");
  for(i=2; i<1000; i++){
    s = bignum_add(s, s)
    m = bignum_mul(m, n2)
    l = bignum_lshiftBits(l, 1)
    #p = bignum_pow(n2, bignum_fromstr(i))
    if(bignum_ne(s, m))
      return ok(0) " (i=" i ", s=" s ", m=" m ")";
    if(bignum_ne(s, l))
      return ok(0) " (i=" i ", s=" s ", m=" l ")";
    #if(bignum_ne(s, p))
    #  return ok(0) " (i=" i ", s=" s ", p=" p ")";
  }
  return ok(1);
}

function test_div(){
  return ok(bignum_eq( \
    bignum_div(bignum_fromstr(2133), bignum_fromstr(3)), \
    bignum_fromstr(711) \
  ))
}

function test_prime1(num,
  factor, qr, one, factors){
  factors = ""
  factor = bignum_fromstr(2)
  one = bignum_fromstr(1)
  num = bignum__treat(num)
  while(bignum_gt(num, one)){
    do{
      split(bignum_divqr(num, factor), qr, "|")
      if(!bignum_iszero(qr[2]))
	break
      num = qr[1]
      factors = factors ":" bignum_tostr(factor)
    }while(1)
    factor = bignum_add(factor, one)
  }
  return ok(factors==":3:3:3:79")
}

function test_convert(){
  return ok(bignum_tostr(bignum_fromstr("2"))=="2") \
    ", " ok(bignum_tostr(bignum_fromstr("-1"))=="-1") \
    ", " ok(bignum_tostr(bignum_fromstr("10000"))=="10000") \
    ", " ok(bignum_tostr(bignum_fromstr("100000"))=="100000") \
    ", " ok(bignum_tostr(bignum_fromstr("21112764814256435"))=="21112764814256435") \
    ", " ok(bignum_tostr(bignum_fromstr("2111276481425643500000000000000000000000000000000000000000000000000000000000000000"))=="2111276481425643500000000000000000000000000000000000000000000000000000000000000000")
}

function test_mod(n,    i, m) {
  if (n == "")
    n = 10 + (LONG ? 5 : 0)
  i = 13
  while (bignum_eq(1, bignum_mod(i, 12))) {
    i = bignum_mul(i, i)
    #i = bignum_mul(i, 13)
    if (n-- < 2)
      return ok(1)
  }
  print "failed: " bignum_tostr(i) " % 12 != 1"
  print "internal data representation: " i
  return ok(0)
}

BEGIN {
  print "Test fromstr: " test_fromstr()
  print "Test add: " test_add()
  print "Test mul: " test_mul()
  if(LONG) {
    print "Test powers_of_two: " test_powers_of_two()
  }
  print "Test convert: " test_convert()
  print "Test div: " test_div()
  print "Test mod: " test_mod()
  print "Test prime1: " test_prime1(2133)
}
