:next-line
$!{
  N
  bnext-line
}

# join lines after {
s/{\
/{/g

# and before }
s/\
}/}/g
