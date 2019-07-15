--[[
    bits-UI Setup: Post installation setup for bits-UI
    Copyright (C) 2019 Alee14

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
]]--
os.loadAPI("/system/apis/sha256.lua")

term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.white)

fs.makeDir("/home/Documents")
fs.makeDir("/home/Downloads")
fs.makeDir("/home/Pictures")

if fs.exists("/system/skel/README.txt") then
    shell.run("copy", "/system/skel/README.txt", "/home/Documents")
else
    print("[ERROR] Unable to find README.txt...")
end

if fs.exists("/system/skel/.background") then
    shell.run("copy", "/system/skel/.background", "/home")
else
    print("[ERROR] Unable to find the background...")
end

print("Welcome to the bits-UI Post Setup!")
sleep(2)
print("Please enter your password.")
print("(Don't set your real password in servers.)")
local passPath = "/etc/passwd.pwd"
local passwd = read(" ")
local insertPasswd = fs.open(passPath, "a")
insertPasswd.writeLine(passwd)
insertPasswd.close()
print("Thanks, I will save that.")

sleep(1)
shell.run("/system/desktop.lua")