# bignum library in pure awk [VERSION 19Aug2008] based on the Tcl version.
# Copyright (C) 2008 Francisco Castro <fcr@adinet.com.uy>
# Copyright (C) 2004 Salvatore Sanfilippo <antirez at invece dot org>
# Copyright (C) 2004 Arjen Markus <arjen dot markus at wldelft dot nl>
#
# LICENSE
#
# This software is:
# Copyright (C) 2008 Francisco Castro <fcr@adinet.com.uy>
# Copyright (C) 2004 Salvatore Sanfilippo <antirez at invece dot org>
# Copyright (C) 2004 Arjen Markus <arjen dot markus at wldelft dot nl>
# The following terms apply to all files associated with the software
# unless explicitly disclaimed in individual files.
#
# The authors hereby grant permission to use, copy, modify, distribute,
# and license this software and its documentation for any purpose, provided
# that existing copyright notices are retained in all copies and that this
# notice is included verbatim in any distributions. No written agreement,
# license, or royalty fee is required for any of the authorized uses.
# Modifications to this software may be copyrighted by their authors
# and need not follow the licensing terms described here, provided that
# the new terms are clearly indicated on the first page of each file where
# they apply.
#
# IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY
# FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
# ARISING OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY
# DERIVATIVES THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE
# IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE
# NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
# MODIFICATIONS.
#
# GOVERNMENT USE: If you are acquiring this software on behalf of the
# U.S. government, the Government shall have only "Restricted Rights"
# in the software and related documentation as defined in the Federal
# Acquisition Regulations (FARs) in Clause 52.227.19 (c) (2).  If you
# are acquiring the software on behalf of the Department of Defense, the
# software shall be classified as "Commercial Computer Software" and the
# Government shall have only "Restricted Rights" as defined in Clause
# 252.227-7013 (c) (1) of DFARs.  Notwithstanding the foregoing, the
# authors grant the U.S. Government and others acting in its behalf
# permission to use and distribute the software in accordance with the
# terms specified in this license.

# TODO
# - pow and powm should check if the exponent is zero in order to return one

#################################### Misc ######################################

# Don't change atombits define if you don't know what you are doing.
# Note that it must be a power of two, and that 16 is too big
# because expr may overflow in the product of two 16 bit numbers.

BEGIN {
  bignum_atombits = 16
  bignum_atombase = 2 ^ bignum_atombits
  bignum_atommask = bignum_atombase - 1
}

# Note: to change 'atombits' is all you need to change the
# library internal representation base.

############################ Basic bignum operations ###########################

# Returns a new bignum initialized to the value of 0.
#
# The big numbers are represented as a Tcl lists
# The all-is-a-string representation does not pay here
# bignums in Tcl are already slow, we can't slow-down it more.
#
# The bignum representation is [list bignum <sign> <atom0> ... <atomN>]
# Where the atom0 is the least significant. Atoms are the digits
# of a number in base 2^$::math::bignum::atombits
#
# The sign is 0 if the number is positive, 1 for negative numbers.

# Note that the function accepts an argument used in order to
# create a bignum of <atoms> atoms. For default zero is
# represented as a single zero atom.
#
# The function is designed so that "set b [zero [atoms $a]]" will
# produce 'b' with the same number of atoms as 'a'.
function bignum_zero(value,
  v){
  v = "bignum 0 0"
  while(value-->1)
    v = v " 0"
  return v
}

# Get the bignum sign
function bignum_sign(bignum,
  tmparr){
  split(bignum, tmparr)
  return tmparr[2]
}

# Get the number of atoms in the bignum
function bignum_atoms(bignum,
  tmparr){
  return split(bignum, tmparr) - 2
}

# Get the i-th atom out of a bignum.
# If the bignum is shorter than i atoms, the function
# returns 0.
function bignum_atom(bignum, i,
  tmparr, n){
  n = split(bignum, tmparr);
  if(n - 3 < i){
    return 0
  }
  return tmparr[i + 3]
}

# Set the i-th atom out of a bignum. If the bignum
# has less than 'i+1' atoms, add zero atoms to reach i.
function bignum_setatom(bignum, i, atomval,
  bignuml, bignumr){
  bignumr = bignum
  sub("([^ ]+ +){" i "}", "", bignumr)
  bignuml = substr(bignum, 1, length(bignum) - length(bignumr))
  sub("[^ ]+ +", "", bignumr)
  return bignuml atomval " " bignumr
}

# Set the bignum sign
function bignum_setsign(bignum, sign){
  sub("bignum [^ ]*", "bignum " sign, bignum)
  return bignum
}

# Remove trailing atoms with a value of zero
# The normalized bignum is returned
function bignum_normalize(bignum){
  sub("( 0)*$", "", bignum)
  if(bignum !~ /^bignum +[^ ]+ +[^ ]+/)
    return "bignum 0 0"
  return bignum
}

# Return the absolute value of N
function bignum_abs(bignum){
  return bignum_setsign(bignum, 0)
}

################################# Comparison ###################################

# Compare by absolute value. Called by bignum_cmp after sign check.
# Returns: 1 if |a| > |b|
#          0 if |a| == |b|
#         -1 if |a| < |b|
function bignum_abscmp(a, b,
  na, nb, arr_a, arr_b, j){
  na = split(a, arr_a)
  nb = split(b, arr_b)
  if(na > nb)
    return 1
  else if(na < nb)
    return -1
  for(j = na; j > 2; j--){
    if(arr_a[j] > arr_b[j])
      return 1
    else if(arr_a[j] < arr_b[j])
      return -1
  }
  return 0
}

# High level comparison. Returns values:
#  1 if a > b
#  0 if a == b
# -1 if a < b
function bignum_cmp(a, b){
  a = bignum__treat(a)
  b = bignum__treat(b)
  if(bignum_sign(a) == bignum_sign(b)){
    if(!bignum_sign(a))
      return bignum_abscmp(a, b)
    else
      return -bignum_abscmp(a, b)
  } else {
    # different sign case:
    if(bignum_sign(a))
      return -1
    return 1
  }
}

# Return 1 if z is 0.
function bignum_iszero(bignum,
  n, tmparr){
  bignum = bignum__treat(bignum)
  n = split(bignum, tmparr)
  return (n == 3)&&(tmparr[3]==0)
}

# Comparison facilities
function bignum_lt(a, b){ return bignum_cmp(a, b) < 0 }
function bignum_le(a, b){ return bignum_cmp(a, b) <= 0 }
function bignum_gt(a, b){ return bignum_cmp(a, b) > 0 }
function bignum_ge(a, b){ return bignum_cmp(a, b) >= 0 }
function bignum_eq(a, b){ return bignum_cmp(a, b) == 0 }
function bignum_ne(a, b){ return bignum_cmp(a, b) != 0 }

########################### Addition / Subtraction #############################

# Add two bignums, don't care about the sign.
function bignum_rawAdd(a, b,
  na, nb, j, arr_a, arr_b, r, car, sum){
  na = split(a, arr_a)
  nb = split(b, arr_b)
  for(j=na + 1; j <= nb; j++) arr_a[j] = 0
  for(j=nb + 1; j <= na; j++) arr_b[j] = 0
  r = "bignum 0"
  car = 0
  for(j=3; j<=na; j++){
    sum = arr_a[j] + arr_b[j] + car
    car = rshift(sum, bignum_atombits)
    r = r " " and(sum, bignum_atommask)
  }
  if(car) r = r " " car
  return bignum_normalize(r)
}

# Subtract two bignums, don't care about the sign. a > b condition needed.
function bignum_rawSub(a, b,
  na, nb, j, arr_a, arr_b, r, car, subs){
  na = split(a, arr_a)
  nb = split(b, arr_b)
  r = "bignum 0"
  # b padding:
  for(j=nb + 1; j <= na; j++) arr_b[j] = 0
  car = 0
  for(j=3; j<=na; j++){
    subs = arr_a[j] - arr_b[j] - car
    if(subs < 0){
      subs += bignum_atombase
      car = 1
    } else
      car = 0
    r = r " " subs
  }
  # Note that if a > b there is no car in the last for iteration
  return bignum_normalize(r)
}

# Higher level addition, care about sign and call rawAdd or rawSub
# as needed.
function bignum_add(a, b,
  cmp, s){
  a = bignum__treat(a)
  b = bignum__treat(b)
  s = bignum_sign(a)
  if(s == bignum_sign(b))
    return bignum_setsign(bignum_rawAdd(a, b), s)
  # different sign case:
  cmp = bignum_abscmp(a, b)
  if(cmp==0)
    return bignum_zero()
  if(cmp==1)
    return bignum_setsign(bignum_rawSub(a, b), s==1)
  if(cmp==-1)
    return bignum_setsign(bignum_rawSub(b, a), !(s==1))
}

# Higher level substraction, care about sign and call rawAdd or rawSub
# as needed.
function bignum_sub(a, b,
  cmp, s){
  a = bignum__treat(a)
  b = bignum__treat(b)
  s = bignum_sign(a)
  if(s != bignum_sign(b))
    return bignum_setsign(bignum_rawAdd(a, b), s)
  # same sign case:
  cmp = bignum_abscmp(a, b)
  if(cmp==0)
    return bignum_zero()
  if(cmp==1)
    return bignum_setsign(bignum_rawSub(a, b), s==1)
  if(cmp==-1)
    return bignum_setsign(bignum_rawSub(b, a), !(s==1))
}

############################### Multiplication #################################

BEGIN {
  bignum_karatsubaThreshold = 32
}

# Multiplication. Calls Karatsuba that calls Base multiplication under
# a given threshold.
function bignum_mul(a, b){
  a = bignum__treat(a)
  b = bignum__treat(b)
  # The sign is the xor between the two signs
  return bignum_setsign(bignum_kmul(a, b),
			xor(bignum_sign(a), bignum_sign(b)))
}

# Karatsuba Multiplication
function bignum_kmul(a, b,
  na, nb, arr_a, arr_b, n, nmin, m, x0, x1, y0, y1, p1, p2, p3){

  na = split(a, arr_a)
  nb = split(b, arr_b)
  n = (na > nb ? na : nb) - 2
  nmin = (na < nb ? na : nb) - 2

  if(nmin < bignum_karatsubaThreshold)
    return bignum_bmul(a, b)

  m = int(n / 2 + 0.6)

  x0 = y0 = x1 = y1 = "bignum 0"
  for(i = 3; i <= m + 2; i++){
    x0 = x0 " " arr_a[i]
    y0 = y0 " " arr_b[i]
  }
  for(i = m + 3; i <= na; i++)
    x1 = x1 " " arr_a[i]
  for(i = m + 3; i <= nb; i++)
    y1 = y1 " " arr_b[i]

  p1 = bignum_kmul(x1, y1)
  p2 = bignum_kmul(x0, y0)
  p3 = bignum_kmul(bignum_add(x1, x0), bignum_add(y1, y0))

  p3 = bignum_sub(p3, p1)
  p3 = bignum_sub(p3, p2)
  p1 = bignum_lshiftAtoms(p1, m * 2)
  p3 = bignum_lshiftAtoms(p3, m)
  p3 = bignum_add(p3, p1)
  p3 = bignum_add(p3, p2)
  return p3
}

# Base Multiplacation.
function bignum_bmul(a, b,
  i, j, na, nb, arr_a, arr_b, arr_r, car){
  na = split(a, arr_a)
  nb = split(b, arr_b)
  split(bignum_zero(na + nb - 3), arr_r)
  for(j=3; j <= nb; j++){
    car = 0
    for(i=3; i <= na; i++){
      # note that A = B * C + D + E
      # with A of N*2 bits and C,D,E of N bits
      # can't overflow since:
      # (2^N-1)*(2^N-1)+(2^N-1)+(2^N-1) == 2^(2*N)-1
      mul = arr_a[i]*arr_b[j]+arr_r[i+j-3]+car
      car = rshift(mul, bignum_atombits)
      mul = and(mul, bignum_atommask)
      arr_r[i+j-3] = mul
    }
    if(car)
      arr_r[na+j-2] = car
  }
  # There's no need to normalize
  return bignum_arrayToList(arr_r)
}

# Left shift 'bignum' of 'n' atoms. Low-level function used by bignum_lshift.
# Exploit the internal representation to go faster.
function bignum_lshiftAtoms(bignum, n){
  while(n--)
    sub("^bignum *[^ ]*", "& 0", bignum)
  return bignum
}

# Right shift 'bignum' of 'n' atoms. Low-level function used by bignum_lshift
# Exploit the internal representation to go faster.
function bignum_rshiftAtoms(bignum, n,
  tmp){
  tmp = bignum
  if(!sub("^bignum *[^ ]*( +[^ ]+){" i "}", "", bignum))
    return "bignum 0 0"
  sub("^bignum *[^ ]*", "", tmp)
  return tmp
}

# Left shift 'bignum' of 'n' bits. Low-level function used by bignum_lshift
# 'n' must be <= bignum_atombits
function bignum_lshiftBits(bignum, n,
  atoms, arr, car, j, t){
  atoms = split(bignum, arr)
  car = 0
  for(j=3; j <= atoms; j++){
    t = arr[j]
    arr[j] = or(car, and(lshift(t, n), bignum_atommask))
    car = rshift(t, bignum_atombits - n)
  }
  if(car)
    arr[atoms+1] = car
  return bignum_arrayToList(arr) # No normalization needed
}

# Right shift 'bignum' of 'n' bits. Low-level function used by bignum_rshift
# 'n' must be <= bignum_atombits
function bignum_rshiftBits(bignum, n,
  atoms, arr, car, j, t){
  atoms = split(bignum, arr)
  car = 0
  for(j=atoms; j >= 3; j--){
    t = arr[j]
    arr[j] = or(car, rshift(t, n))
    car = and(lshift(t, bignum_atombits - n), bignum_atommask)
  }
  # There's no need to normalize
  return bignum_arrayToList(arr)
}

# Left shift 'bignum' of 'n' bits.
function bignum_lshift(bignum, n,
  atoms, bits){
  bignum = bignum__treat(bignum)
  atoms = int(n / bignum_atombits)
  bits = int(n % bignum_atombits)
  if(atoms)
    bignum = bignum_lshiftAtoms(bignum, atoms)
  if(bits)
    bignum = bignum_lshiftBits(bignum, bits)
  return bignum
}

# Right shift 'bignum' of 'n' bits.
function bignum_rshift(bignum, n,
  atoms, bits, corr, j){
  bignum = bignum__treat(bignum)
  atoms = int(n / bignum_atombits)
  bits = int(n % bignum_atombits)
  # correct for "arithmetic shift" - signed integer:
  corr = 0
  if(bignum_sign(bignum)==1){
    for(j=atoms+2; j>=3; j++)
      if(arr[j]!=0){
	corr = 1
	break
      }
    if(!corr){
      if(and(arr[atoms+3], compl(lshift(bignum_atommask, bits)) ) != 0){
	corr = 1
      }
    }
  }
  if(atoms)
    bignum = bignum_lshiftAtoms(bignum, atoms)
  if(bits)
    bignum = bignum_lshiftBits(bignum, bits)
  if(corr)
    bignum = bignum_sub(bignum, 1)
  return bignum
}

############################### Bit oriented ops ###############################

# Set the bit 'n' of 'bignum'
function bignum_setbit(bignum, n,
  atom, bit, len, arr){
  atom = int(n / bignum_atombits) + 3
  bit = lshift(1, int(n % bignum_atombits))
  len = split(bignum, arr)
  while(atom > len)
    arr[len++] = 0
  arr[len] = or(arr[len], bit)
  return bignum_arrayToList(arr)
}

# Clear the bit 'n' of 'bignum'
function bignum_clearbit(bignum, n,
  atom, arr, len){
  atom = int(n / bignum_atombits) + 3
  len = split(bignum, arr)
  if(atom > len)
    return bignum
  mask = xor(bignum_atommask, lshift(1, int(n % bignum_atombits)))
  arr[atom] = and(arr[atom], mask)
  return bignum_arrayToList(arr)
}

# Test the bit 'n' of 'bignum'. Returns 1 if the bit is set.
function bignum_testbit(bignum, n){
  atom = int(n / bignum_atombits) + 3
  len = split(bignum, arr)
  if(atom > len)
    return 0
  mask = lshift(1, int(n % bignum_atombits))
  return and(arr[atom], mask) != 0
}

# does bitwise AND between a and b
function bignum_bitand(a, b,
  j, n, na, nb, r, arr_a, arr_b){
  # The internal number rep is little endian. Appending zeros is
  # equivalent to adding leading zeros to a regular big-endian
  # representation. The two numbers are extended to the same length,
  # then the operation is applied to the absolute value.
  na = split(bignum__treat(a), arr_a)
  nb = split(bignum__treat(b), arr_b)
  # set r with the sign of a:
  r = "bignum " arr_[2]
  for(j=na + 1; j <= nb; j++) arr_a[j] = 0
  for(j=nb + 1; j <= na; j++) arr_b[j] = 0
  n = na>nb ? na : nb
  for(j=3; j <= n; j++)
    r = r " " and(arr_a[j], arr_b[j])
  return bignum_normalize(r)
}

# does bitwise XOR between a and b
function bignum_bitxor(a, b,
  j, n, na, nb, r, arr_a, arr_b){
  na = split(bignum__treat(a), arr_a)
  nb = split(bignum__treat(b), arr_b)
  # set r with the sign of a:
  r = "bignum " arr_[2]
  for(j=na + 1; j <= nb; j++) arr_a[j] = 0
  for(j=nb + 1; j <= na; j++) arr_b[j] = 0
  n = na>nb ? na : nb
  for(j=3; j <= n; j++)
    r = r " " xor(arr_a[j], arr_b[j])
  return bignum_normalize(r)
}

# does bitwise OR between a and b
function bignum_bitor(a, b,
  j, n, na, nb, r, arr_a, arr_b){
  na = split(bignum__treat(a), arr_a)
  nb = split(bignum__treat(b), arr_b)
  # set r with the sign of a:
  r = "bignum " arr_[2]
  for(j=na + 1; j <= nb; j++) arr_a[j] = 0
  for(j=nb + 1; j <= na; j++) arr_b[j] = 0
  n = na>nb ? na : nb
  for(j=3; j <= n; j++)
    r = r " " or(arr_a[j], arr_b[j])
  return bignum_normalize(r)
}

# Return the number of bits needed to represent 'bignum'.
function bignum_bits(bignum,
  bits){
  bits = (bignum_atoms(bignum) - 1)*bignum_atombits
  sub(/.* /, "", bignum)
  while(0 != bignum){
    bignum = rshift(bignum, 1)
    bits++
  }
  return bits
}

################################### Division ###################################

# Division. Returns [list n/d n%d]
#
# I got this algorithm from PGP 2.6.3i (see the mp_udiv function).
# Here is how it works:
#
# Input:  N=(Nn,...,N2,N1,N0)radix2
#         D=(Dn,...,D2,D1,D0)radix2
# Output: Q=(Qn,...,Q2,Q1,Q0)radix2 = N/D
#         R=(Rn,...,R2,R1,R0)radix2 = N%D
#
# Assume: N >= 0, D > 0
#
# For j from 0 to n
#      Qj <- 0
#      Rj <- 0
# For j from n down to 0
#      R <- R*2
#      if Nj = 1 then R0 <- 1
#      if R => D then R <- (R - D), Qn <- 1
#
# Note that the doubling of R is usually done leftshifting one position.
# The only operations needed are bit testing, bit setting and subtraction.
#
# This is the "raw" version, don't care about the sign, returns both
# quotient and rest as a two element list.
# This procedure is used by divqr, div, mod, rem.
function bignum_rawDiv(num, div,
  n, arr_num, res, arr_quo, bit, b_atom, b_bit, p){
  n = split(num, arr_num)
  res = "bignum 0 0"
  split(bignum_zero(n), arr_quo)
  for(bit = bignum_bits(num) - 1; bit >= 0; bit--){
    b_atom = int(bit / bignum_atombits) + 3
    b_bit = lshift(1, and(bit, bignum_atombits - 1))
    res = bignum_lshiftBits(res, 1)
    if(and(arr_num[b_atom], b_bit)){
      # Exploit the internal structure to make an OR 1, very fast in
      # terms of awk, no need to split and join it:
      p = index(substr(res, 10), " ")
      p = (!p)? length(res) : p+9
      res = substr(res, 1, p-1) or(substr(res, p, 1), 1) substr(res, p+1)
    }
    if(bignum_abscmp(res, div) >= 0){
      res = bignum_rawSub(res, div)
      arr_quo[b_atom] = or(arr_quo[b_atom], b_bit)
    }
  }
  # There's no need to normalize
  return bignum_arrayToList(arr_quo) "|" res
}

# Divide by single-atom immediate. Used to speedup bignum -> string conversion.
# The procedure returns a two-elements list with the bignum quotient and
# the remainder (that's just a number being <= of the max atom value).
function bignum_rawDivByAtom(num, div,
  atoms, arr_n){
  atoms = split(num, arr_num) - 2
  t = 0
  for(j = atoms; j > 0; j--){
    t = lshift(t, bignum_atombits) + arr_num[j+2]
    arr_num[j+2] = int(t / div)
    t = int(t % div)
  }
  # There's no need to normalize
  return bignum_arrayToList(arr_num) "|" t
}

# Higher level division. Returns a list with two bignums, the first is
# the quotient of n/d, the second the remainder n%d.
# Note that if you want the *modulo* operator you shoud use bignum_mod
#
# The remainder sign is always the same as the divident.
function bignum_divqr(n, d,
  res){
  n = bignum__treat(n)
  d = bignum__treat(d)
  if(bignum_iszero(d)){
    print "Error: Division by zero"
    return
  }
  split(bignum_rawDiv(n, d), res, "|")
  res[1] = bignum_setsign(res[1], xor(bignum_sign(n), bignum_sign(d)))
  res[2] = bignum_setsign(res[2], bignum_sign(n))
  return res[1] "|" res[2]
}

# Like divqr, but only the quotient is returned.
function bignum_div(n, d,
  arr){
  split(bignum_divqr(n, d), arr, "|")
  return arr[1]
}

# Like divqr, but only the remainder is returned.
function bignum_rem(n, d,
  arr){
  split(bignum_divqr(n, d), arr, "|")
  return arr[2]
}

# Modular reduction. Returns N modulo M
function bignum_mod(n, m,
  r){
  n = bignum__treat(n)
  m = bignum__treat(m)
  r = bignum_rem(n, m)
  if(bignum_sign(m) != bignum_sign(r)){
    r = bignum_add(r, m)
  }
  return r
}

# Returns true if n is odd
function bignum_isodd(n){
  return n ~ /^bignum +[^ ]*[13579](\>|$)/
}

# Returns true if n is even
function bignum_iseven(n){
  return n ~ /^bignum +[^ ]*[02468](\>|$)/
}

############################ Power and Power mod N ############################

# Returns b^e
function bignum_pow(b, e,
  one, r){
  b = bignum__treat(b)
  e = bignum__treat(e)
  one = "bignum 0 1"
  if(bignum_iszero(e))
    return one
  # The power is negative is the base is negative and the exponent is odd
  sign = bignum_iszero(b) && bignum_isodd(e)
  # Set the base to it's abs value, i.e. make it positive
  b = bignum_setsign(b, 0)
  # Main loop
  r = one # Start with result = 1
  while(bignum_abscmp(e, one)>0){ # While the exp > 1
    if(bignum_isodd(e)){
      r = bignum_mul(r, b)
    }
    e = bignum_rshiftBits(e, 1) # exp = exp / 2
    b = bignum_mul(b, b)
  }
  r = bignum_mul(r, b)
}

# Fast power mod N function.
# Returns b^e mod m
function bignum_powm(b, e, m,
  t){
  b = bignum__treat(b)
  e = bignum__treat(e)
  m = bignum__treat(m)
  b = bignum_mod(b, m)
  t = "bignum 0 1"
  while(!bignum_iszero(e)){
    if(bignum_isodd(e))
      t = bignum_mod(bignum_mul(t, b), m)
    x = bignum_mod(bignum_mul(x, x), m)
    e = bignum_rshiftBits(e, 1)
  }
  return r
}

################################# Square Root #################################

# SQRT using the 'binary sqrt algorithm'.
#
# The basic algoritm consists in starting from the higer-bit
# the real square root may have set, down to the bit zero,
# trying to set every bit and checking if guess*guess is not
# greater than 'n'. If it is greater we don't set the bit, otherwise
# we set it. In order to avoid to compute guess*guess a trick
# is used, so only addition and shifting are really required.
function bignum_sqrt(n){
}

################################ Random Number ################################

# Returns a random number in the range [0,2^n-1]
function bignum_rand(bits){
}

################################ Prime numbers ################################

function bignum_millerrabin(bignum, count){
}

########################## Convertion to/from string ##########################

# The string representation charset. Max base is 36
BEGIN {
  bignum_cset = "0123456789abcdefghijklmnopqrstuvwxyz"
}

# Convert 'z' to a string representation in base 'base'.
# Note that this is missing a simple but very effective optimization
# that's to divide by the biggest power of the base that fits
# in a Tcl plain integer, and then to perform divisions with '/'.
function bignum_tostr(z, base,
  str, sign, t, qr){
  if(base=="")
    base=10
  if(length(bignum_cset) < base){
    print "Error: base too big for string conversion"
    return
  }
  if(bignum_iszero(z))
    return 0
  sign = bignum_sign(z)
  while(!bignum_iszero(z)){
    t = bignum_rawDivByAtom(z, base)
    split(t, qr, "|")
    str = substr(bignum_cset, qr[2] + 1, 1) str
    z = qr[1]
  }
  return (int(sign)?"-":"") str
}

# Create a bignum from a string representation in base 'base'.
function bignum_fromstr(str, base,
  sign, bigbase, digitval, z){
  if(base=="")
    base=0
  sub("^ *", "", str)
  sub(" *$", "", str)
  sign=0
  if(str ~ /^-/){
    sign=1
    sub("-", "", str)
  }
  str = tolower(str)
  if(base == 0){
    if(str ~ /^0x/){
      base = 16; sub("0x", "", str)
    } else if(str ~ /^ox/) {
      base = 8; sub("ox", "", str)
    } else if(str ~ /^bx/) {
      base = 2; sub("bx", "", str)
    } else
      base = 10
  }
  if(length(bignum_cset) < base){
    print "Error: base too big for string conversion"
    return
  }
  bigbase = "bignum 0 " base	# build a bignum with the base value
  z = "bignum 0 0"
  for(i = 1; i <= length(str); i++){
    digitval = index(bignum_cset, substr(str, i, 1))
    if(!digitval){
      print "Error: Illegal char " substr(str, i, 1) " for base " base
      return
    }
    z = bignum_mul(z, bigbase)
    z = bignum_rawAdd(z, "bignum 0 " (digitval - 1))
  }
  if(!bignum_iszero(z) && sign)
    return bignum_setsign(z, sign)
  return z
}

function bignum__treat(num,
  arr){
  if(num ~ /^bignum /)
    return num
  if(num=="0")
    return "bignum 0 0"
  if(num=="1")
    return "bignum 0 1"
  if(num ~ /^-?([0Oob]x)?[0-9]+/)
    return bignum_fromstr(num)
  print "Error: Invalid bignum number", num
}

function bignum__dumpArray(arr,
  i){
  for(i=1; arr[i]!=""; i++)
    printf("<%s>", arr[i])
  print
}

# There's no need to normalize after bignum_arrayToList
function bignum_arrayToList(arr_r,
  r, i, z){
  # "bignum" and sign:
  r = arr_r[1] " " arr_r[2]
  i = 3
  while(arr_r[i] == "0"){
    z = z " 0"
    i++
  }
  if(arr_r[i]=="")
    return r " 0"
  while(arr_r[i] != ""){
    while(arr_r[i] == "0"){
      z = z " 0"
      i++
    }
    if(arr_r[i] == ""){
      return r
    }
    r = r z " " arr_r[i++]
    z = ""
  }
  return r
}

