term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.white)
print("Welcome to the bits-UI transfer!")
sleep(2)
if fs.exists("/disk") then
    shell.run("copy", "/home", "/disk")
    shell.run("copy", "/etc/passwd.pwd", "/disk")
else
    print("You need a floppy disk to copy over data.")
    print("Installation has been halted.")
    sleep(2)
end