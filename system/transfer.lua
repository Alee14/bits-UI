term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.white)
print("Welcome to the bits-UI transfer!")
if fs.exists("/disk") then
    shell.run("copy", "/home", "/disk")
end