#!/bin/sh
"exec" "awk" "-f" "../ircbot.awk" "-f" "$0" "$@"
{}

BEGIN {
  on_every_event = 1
  connect()
}

function on_every(params) {
  # Test when joined
  if (params["command"] == "JOIN" && params["prefix_nick"] irc_nick) {
    irc_privmsg(params["args"], "Hi, I'm a crazy bot.")
  }
}
