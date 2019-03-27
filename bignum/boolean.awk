# Boolean replacement functions

function bit_lshift(n, times) {
  n += 0
  times += 0
  return int(n * 2 ^ times)
}

function bit_rshift(n, times) {
  n += 0
  times += 0
  return int(n / 2 ^ times)
}

function bit_and(n1, n2,    byte_val, res) {
  n1 += 0
  n2 += 0
  res = 0
  byte_val = 1
  while(n1 || n2) {
    if(n1 % 2 && n2 % 2) res += byte_val
    n1 = int(n1 / 2)
    n2 = int(n2 / 2)
    byte_val *= 2
  }
  return res
}

function bit_or(n1, n2,    byte_val, res) {
  n1 += 0
  n2 += 0
  res = 0
  byte_val = 1
  while(n1 || n2) {
    if(n1 % 2 || n2 % 2) res += byte_val
    n1 = int(n1 / 2)
    n2 = int(n2 / 2)
    byte_val *= 2
  }
  return res
}

function bit_xor(n1, n2,    byte_val, res) {
  n1 += 0
  n2 += 0
  res = 0
  byte_val = 1
  while(n1 || n2) {
    if(n1 % 2 != n2 % 2) res += byte_val
    n1 = int(n1 / 2)
    n2 = int(n2 / 2)
    byte_val *= 2
  }
  return res
}

function bit_not(n,    byte_val) {
  n += 0
  byte_val = 1
    while(byte_val < n) byte_val *= 2
    return byte_val - n
}

function bit_compl(n,    i, byte_val, res) {
  n += 0
  res = 0
  for(i = 52; i >= 0; i--) {
    byte_val = 2 ^ i
    if(!int(n / byte_val)) res += byte_val
    n %= byte_val
  }
  return res
}

BEGIN {
  print xor(3, 6)
}
