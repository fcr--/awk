:repeat

# Delete lines between @begin_delete_on_simplify and @end_delete_on_simplify
/#[^"/]*@begin_delete_on_simplify\>[^"/]*$/,/#[^"/]*@end_delete_on_simplify\>[^"/]*$/d

# Delete lines with @delete_on_simplify
/#[^"/]*@delete_on_simplify\>[^"/]*$/ d

# UNSAFE: inline tget:
/function/!s/\<tget(\([^,)"]*\), *\([^,)"]*\), *\(\([^,)"]\|"\([^"\\]\|\\.\)*"\)*\))/\1[\2,\3]/g

# (only if no regexp in place) delete comments:
/^[^#]*\/.*\//!s/^\(\([^"#]\|"\([^"\\]\|\\.\)*"\)*\)#.*/\1/
# (only if no regexp in place) delete spaces after commas:
:repcomma
/\/.*[",].*\//!s/^\(\([^",]\|,[^ ]\|,\{,1\}"\([^"\\]\|\\.\)*"\)*\) *,  */\1,/
trepcomma
:repsemicolon
/\/.*[";].*\//!s/^\(\([^";]\|;[^ ]\|;\{,1\}"\([^"\\]\|\\.\)*"\)*\) *;  */\1;/
trepsemicolon
:repeq
/\/.*["=].*\//!s/^\(\([^"= ]\| [^="]\|=[^ ]\|[= ]\{,1\}"\([^"\\]\|\\.\)*"\)*\) *\(==*\)  */\1\4/
trepeq
:repprequote
/\/.*".*\//!s/^\(\([^" ]\| [^"]\|"\([^"\\]\|\\.\)*"\)*\)  *"/\1"/
trepprequote
:reppostquote
/\/.*".*\//!s/^\(\([^"]\|\("\([^"\\]\|\\.\)*"\)*[^ "]\)*"\([^"\\]\|\\.\)*"\)  */\1/
treppostquote
# SAFE: delete spaces before opening braces at the eol:
s/  *{ *$/{/
# SAFE: delete whitespace at line borders:
s/^[ 	]*//
s/[ 	]*$//
# SAFE: delete spaces after close brace at the beginning:
s/^}  */}/
# check hold space if there's text from previous line concatenations
x
/^$/!{
  # append the next line:
  G; s/\
/ /;
  # and then delete the other space
  x; s/.*//; x
  # run optimizations one more time...
  brepeat
}
x
# SAFE: join lines if it ends in backslash
/\\ *$/{
  s/ *\\ *$//
  x
  N
  s/\
//
  brepeat
}
# SAFE: delete empty lines:
/^$/d
