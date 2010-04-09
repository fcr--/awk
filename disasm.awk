#!/usr/bin/awk -f

# Use with:
# echo hex code to disassembly | ./disasm.awk -v org=DecimalNum -v list=myfile
# Or: od -t x1 program.bin | sed 's/^[^ ]*//' | ./disawk ...
# Or just send hex 6502 machine code to the stdin of this script.

BEGIN {
  hexmap = "123456789abcdef"
  if (!org)
    org = 0x600
  # list = "myfile.list"

  #      x0  x1  x2  x3  x4  x5  x6  x7  x8  x9  xA  xB  xC  xD  xE  xF
  split(    "ORA,kil,slo,nop,ORA,ASL,slo,PHP,ORA,ASL,anc,nop,ORA,ASL,slo," \
	"BPL,ORA,kil,slo,nop,ORA,ASL,slo,CLC,ORA,nop,slo,nop,ORA,ASL,slo," \
	"JSR,AND,kil,rla,BIT,AND,ROL,rla,PLP,AND,ROL,anc,BIT,AND,ROL,rla," \
	"BMI,AND,kil,rla,nop,AND,ROL,rla,SEC,AND,nop,rla,nop,AND,ROL,rla," \
	"RTI,EOR,kil,sre,nop,EOR,LSR,sre,PHA,EOR,LSR,alr,JMP,EOR,LSR,sre," \
	"BVC,EOR,kil,sre,nop,EOR,LSR,sre,CLI,EOR,nop,sre,nop,EOR,LSR,sre," \
	"RTS,ADC,kil,rra,nop,ADC,ROR,rra,PLA,ADC,ROR,arr,JMP,ADC,ROR,rra," \
	"BVS,ADC,kil,rra,nop,ADC,ROR,rra,SEI,ADC,nop,rra,nop,ADC,ROR,rra," \
	"nop,STA,nop,sax,STY,STA,STX,sax,DEY,nop,TXA,xaa,STY,STA,STX,sax," \
	"BCC,STA,kil,ahx,STY,STA,STX,sax,TYA,STA,TXS,tas,shy,STA,shx,ahk," \
	"LDY,LDA,LDX,lax,LDY,LDA,LDX,lax,TAY,LDA,TAX,lax,LDY,LDA,LDX,lax," \
	"BCS,LDA,kil,lax,LDY,LDA,LDX,lax,CLV,LDA,TSX,las,LDY,LDA,LDX,lax," \
	"CPY,CMP,nop,dcp,CPY,CMP,DEC,dcp,INY,CMP,DEX,axs,CPY,CMP,DEC,dcp," \
	"BNE,CMP,kil,dcp,nop,CMP,DEC,dcp,CLD,CMP,nop,dcp,nop,CMP,DEC,dcp," \
	"CPX,SBC,nop,isc,CPX,SBC,INC,isc,INX,SBC,NOP,sbc,CPX,SBC,INC,isc," \
	"BEQ,SBC,kil,isc,nop,SBC,INC,isc,SED,SBC,nop,isc,nop,SBC,INC,isc", \
		MNEM, /,/)
  MNEM[0] = "BRK" # split begins with 1, that's why BRK was left out
  split(    "izx,   ,izx,zpa,zpa,zpa,zpa,   ,imm,   ,imm,abs,abs,abs,abs," \
	"rel,izy,   ,izy,zpx,zpx,zpx,zpx,   ,aby,   ,aby,abx,abx,abx,abx," \
	"abs,izx,   ,izx,zpa,zpa,zpa,zpa,   ,imm,   ,imm,abs,abs,abs,abs," \
	"rel,izy,   ,izy,zpx,zpx,zpx,zpx,   ,aby,   ,aby,abx,abx,abx,abx," \
	"   ,izx,   ,izx,zpa,zpa,zpa,zpa,   ,imm,   ,imm,abs,abs,abs,abs," \
	"rel,izy,   ,izy,zpx,zpx,zpx,zpx,   ,aby,   ,aby,abx,abx,abx,abx," \
	"   ,izx,   ,izx,zpa,zpa,zpa,zpa,   ,imm,   ,imm,ind,abs,abs,abs," \
	"rel,izy,   ,izy,zpx,zpx,zpx,zpx,   ,aby,   ,aby,abx,abx,abx,abx," \
	"imm,izx,imm,izx,zpa,zpa,zpa,zpa,   ,imm,   ,imm,abs,abs,abs,abs," \
	"rel,izy,   ,izy,zpx,zpx,zpy,zpy,   ,aby,   ,aby,abx,abx,aby,aby," \
	"imm,izx,imm,izx,zpa,zpa,zpa,zpa,   ,imm,   ,imm,abs,abs,abs,abs," \
	"rel,izy,   ,izy,zpx,zpx,zpy,zpy,   ,aby,   ,aby,abx,abx,aby,aby," \
	"imm,izx,imm,izx,zpa,zpa,zpa,zpa,   ,imm,   ,imm,abs,abs,abs,abs," \
	"rel,izy,   ,izy,zpx,zpx,zpx,zpx,   ,aby,   ,aby,abx,abx,abx,abx," \
	"imm,izx,imm,izx,zpa,zpa,zpa,zpa,   ,imm,   ,imm,abs,abs,abs,abs," \
	"rel,izy,   ,izy,zpx,zpx,zpx,zpx,   ,aby,   ,aby,abx,abx,abx,abx", \
		MODE, /,/)
  MODE[0] = "   " # BRK has "   " (implicit) mode
  PARAMS["   "] = 1
  PARAMS["imm"] = PARAMS["zpa"] = PARAMS["zpx"] = PARAMS["zpy"] = 2
  PARAMS["izx"] = PARAMS["izy"] = PARAMS["rel"] = 2
  PARAMS["abs"] = PARAMS["abx"] = PARAMS["aby"] = PARAMS["ind"] = 3
}

function hex2dec(str,     i, n) {
  str = tolower(str)
  gsub(/[^0-9a-f]/, "", str)
  n = 0
  for (i=1; i<=length(str); i++) {
    n = 16*n + index(hexmap, substr(str, i, 1))
  }
  return n
}

function uint8(n) {
  return (int(n)%256+256)%256
}

function uint16(n) {
  return (int(n)%65536+65536)%65536
}

function int8(n) {
  return (int(n)%256+384)%256-128
}

function print_line(org, BYTES, SYMBOLS, name, sz, format,     i, bytes, params) {
  params = bytes = ""
  for (i=0; i<sz; i++) {
    bytes = bytes sprintf(" %02X", BYTES[org+i])
  }
  if (format == "imm") {
    params = sprintf(" #$%02X", BYTES[org+1])
  } else if (format == "zpa") {
    params = sprintf(" $%02X", BYTES[org+1])
  } else if (format == "zpx") {
    params = sprintf(" $%02X,X", BYTES[org+1])
  } else if (format == "zpy") {
    params = sprintf(" $%02X,Y", BYTES[org+1])
  } else if (format == "izx") {
    params = sprintf(" ($%02X,X)", BYTES[org+1])
  } else if (format == "izy") {
    params = sprintf(" ($%02X),Y", BYTES[org+1])
  } else if (format == "abs") {
    params = sprintf(" $%04X", BYTES[org+1] + 256*BYTES[org+2])
  } else if (format == "abx") {
    params = sprintf(" $%04X,X", BYTES[org+1] + 256*BYTES[org+2])
  } else if (format == "aby") {
    params = sprintf(" $%04X,Y", BYTES[org+1] + 256*BYTES[org+2])
  } else if (format == "ind") {
    params = sprintf(" ($%04X)", BYTES[org+1] + 256*BYTES[org+2])
  } else if (format == "rel") {
    i = uint16(org + 2 + int8(BYTES[org+1]))
    if (i in SYMBOLS) {
      params = SYMBOLS[i]
      sub(/ .*/, "", params)
      params = " " params
    } else
      params = sprintf(" $%04X", i)
  }
  printf "%04X  %-9s   %s\n", org, bytes, name params
}

function disasm(org, BYTES, SYMBOLS,     name) {
  while (org in BYTES) {
    if (org in SYMBOLS)
      print SYMBOLS[org]
    print_line(org, BYTES, SYMBOLS, MNEM[BYTES[org]], PARAMS[MODE[BYTES[org]]], MODE[BYTES[org]])
    org += PARAMS[MODE[BYTES[org]]]
  }
}

function load_xa65_symbols(file, SYMBOLS,     line, n, F) {
  while ((getline line <file)>0) {
    if (split(line, F, /, */) != 4)
      continue
    n = hex2dec(F[2])
    SYMBOLS[n] = SYMBOLS[n] (F[3]>0?".":"") F[1] " "
  }
}

BEGIN {
  org_read = org
  if (list != "")
    load_xa65_symbols(list, SYMBOLS)
}
{
  $0 = tolower($0)
  gsub(/[^0-9a-f]/, "", $0)
  for (i=1; i<=int(length($0)/2); i++) {
    BYTES[org_read] = \
	index(hexmap, substr($0, 2*i-1, 1))*16 + \
	index(hexmap, substr($0, 2*i, 1))
    org_read++
  }
}
END {
  disasm(org, BYTES, SYMBOLS)
}
