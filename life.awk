#!/usr/bin/awk -f
function n(C, x, y) {
  return C[x-1, y-1] + C[x-1, y] + C[x-1, y+1] + C[x, y-1] + C[x, y+1] + \
	 C[x+1, y-1] + C[x+1, y] + C[x+1, y+1]
}

function s(O, N) {
  for (x=1; x<=w; x++)
    for(y=1; y<=h; y++)
      if (O[x, y])
	N[x, y] = (int(n(O, x, y)/2)==1) ? 1 : 0
      else
	N[x, y] = (n(O, x, y)==3) ? 1 : 0
}

function p(C) {
  for (y=1; y<=h; y++) {
    for (x=1; x<=w; x++)
      printf C[x, y] ? "[]" : "  "
    print
  }
  printf "\033[" h "A"
}

BEGIN {
  w = 39
  h = 22
  srand()
  for (x=1; x<=w; x++)
    for (y=1; y<=h; y++)
      T1[x, y] = rand()<0.5?1:0
  while(1) {
    p(T1); s(T1, T2)
    p(T2); s(T2, T1)
  }
}
