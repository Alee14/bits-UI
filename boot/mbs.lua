assert(loadfile("/.mbs/bin/mbs.lua", _ENV))('startup')
term.setTextColor(16)
print(os.version() .. " (+MBS)")
term.setCursorPos(1,2)
term.setTextColor(1)