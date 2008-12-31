#!/bin/sh
"exec" "awk" "-f" "../ircbot.awk" "-f" "$0" "$@"
{}

BEGIN {
  on_every_event = 1
  connect()
}

function on_every(params,  fn) {
  fn = params["arg0"]
  if (params["command"] == "PRIVMSG" && substr(fn, 1, 1) ~ /[#&0-9]/) {
    print params["prefix_nick"]": "params["args"] >> (fn".log")
    fflush(fn".log")
  }
  if (params["command"] == "PART" && params["prefix_nick"] == irc_nick) {
    irc_write("JOIN :" params["arg0"])
    return
  }
  if (params["command"] == "KICK" && params["arg1"] == irc_nick) {
    irc_write("JOIN :" params["arg0"])
    return
  }
}
