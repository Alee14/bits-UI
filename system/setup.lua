term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.white)

if fs.exists("/system/skel/README.txt") then
    shell.run("copy", "/system/skel/README.txt", "/home")
else
    print("[ERROR] Unable to find README.txt...")
end

print("Welcome to the setup!")

sleep(3)
shell.run("/system/desktop.lua")