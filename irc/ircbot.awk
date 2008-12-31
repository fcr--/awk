BEGIN {
  irc_conn = "/inet/tcp/0/irc.freenode.net/6667"
  irc_nick = "awkbot-G"
  #irc_channels = ""
  line_number = 0
  for (i=1; i<ARGC; i++) {
    if (ARGV[i] == "-irc.nick") {
      irc_nick = ARGV[++i]
    } else if (ARGV[i] == "-irc.channels") {
      # Comma separated channel list:
      irc_channels = ARGV[++i]
    } else {
      print "Option " ARGV[i] " not supported."
      print "Syntax: " ARGV[0] " [-irc.nick <NICK>] -irc.channels <CHANNEL_LIST>"
      exit
    }
  }
}

function irc_read(params,
	var, i) {
  for (var in params)
    delete params[var]
  FS = "[ ]"
  RS = ORS = "\r\n"
  do {
    if((irc_status = (irc_conn |& getline)) <= 0) {
      ORS = "\n"
      print "\033[1m" "IRC READ ERROR" "\033[0m"
      exit
    }
  } while (/^$/)
  RS = ORS = "\n"
  print "<- \033[40m\033[32m" $0 "\033[0m"
  if (/^:/) {
    $0 = gensub(/^:(([^ !@]*)!?([^ @]*)@?([^ ]*))/, "\\1 \\2 \\3 \\4 ", 1)
    params["prefix"] = $1
    params["prefix_nick"] = $2
    params["prefix_user"] = $3
    params["prefix_host"] = $4
    $1 = $2 = $3 = $4 = ""
    sub(/ */, "")
  }
  params["command"] = toupper($1)
  sub(/[^ ]* */, "")
  i=0
  while ($0 != "") {
    if (/^:/) {
      params["args"] = substr($0, 2)
      $0 = ""
    } else {
      params["arg" i++] = $1
      sub(/[^ ]* */, "")
    }
  }
  params["argc"] = i
  #for (var in params)
  #  print "  " var ": " params[var]
  return irc_status
}

function irc_write(text) {
  print "-> \033[40m\033[31m" text "\033[0m"
  RS = ORS = "\r\n"
  print text |& irc_conn
  RS = ORS = "\n"
  line_number++
}

function irc_privmsg(channel, text) {
  irc_write("PRIVMSG " channel " :" text)
}

function connect() {
  irc_write("NICK " irc_nick)
  irc_write("USER " irc_nick " 12 - :awk bot (C) Francisco Castro")
  if (irc_channels) {
    irc_write("JOIN " irc_channels)
  }
  while (irc_read(params)) {
    if (on_privmsg_event && params["command"] == "PRIVMSG") {
      on_privmsg(params)
    } else if (params["command"] == "PING") {
      if (params["args"]) {
	irc_write("PONG " params["arg1"] " :" params["args"])
      } else {
	irc_write("PONG " params["arg1"] " " params["arg2"])
      }
    }
    if (on_every_event) {
      on_every(params)
    }
  }
  close(irc_conn)
}

# Example logger bot:
# function on_privmsg(params) {
#   print "From: ", params["prefix"]
#   print "To:   ", params["arg0"]
#   print "      ", params["args"]
# }
# BEGIN {
#   on_privmsg_event = 1
#   connect()
# }
