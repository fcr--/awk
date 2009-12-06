#!/usr/bin/awk -f
function neighbours(TABLE, x, y) {
  return TABLE[x-1, y-1] + TABLE[x, y-1] + TABLE[x+1, y-1] + \
	 TABLE[x-1, y]			 + TABLE[x+1, y] + \
	 TABLE[x-1, y+1] + TABLE[x, y+1] + TABLE[x+1, y+1]
}

function calculate(OLD, NEW) {
  for (x=1; x<=width; x++)
    for(y=1; y<=height; y++)
      if (OLD[x, y])
	NEW[x, y] = (int(neighbours(OLD, x, y)/2)==1) ? 1 : 0
      else
	NEW[x, y] = (neighbours(OLD, x, y)==3) ? 1 : 0
}

function print_table(TABLE) {
  for (y=1; y<=height; y++) {
    for (x=1; x<=width; x++)
      printf TABLE[x, y] ? "[]" : "  "
    print
  }
  printf "\033[" height "A"
}

BEGIN {
  width = 39
  height = 22
  srand()
  for (x=1; x<=width; x++)
    for (y=1; y<=height; y++)
      T1[x, y] = rand()<0.5 ? 1 : 0
  while (1) {
    print_table(T1); calculate(T1, T2)
    print_table(T2); calculate(T2, T1)
  }
}
