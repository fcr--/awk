# Boolean replacement functions

function lshift(num, times){
  return int(num * 2^times)
}

function rshift(num, times){
  return int(num / 2^times)
}

function and(x, y,
  res, i){
  i=1
  while(x && y){
    if((x%2)&&(y%2))
      res+=i;
    x=int(x/2);
    y=int(y/2);
    i*=2;
  }
  return res
}

function or(x, y,
  res, i){
  i=1
  while(x && y){
    if((x%2)||(y%2))
      res+=i;
    x=int(x/2);
    y=int(y/2);
    i*=2;
  }
  return res
}
function xor(x, y,
  res, i){
  i=1
  while(x && y){
    print x, y, i
    if((x%2)&&(!(y%2)) || (y%2)&&!(x%2))
      res+=i;
    x=int(x/2);
    y=int(y/2);
    i*=2;
  }
  return res
}

BEGIN {
  print xor(3, 6)
}
