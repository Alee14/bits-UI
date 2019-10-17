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
os.loadAPI("/system/apis/json.lua")
local config = "/home/.config"

term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.white)

print("Welcome to the bits-UI Post Setup!")
sleep(2)
print("Please enter your password.")
--print("(Don't set your real password in servers.)")

local passPath = "/etc/passwd.pwd"
if fs.exists(passPath) then
    print("[INFO] Password file exists! Skipping.")
    sleep(2)
else
    local passwd = read(" ")
    local insertPasswd = fs.open(passPath, "a")
    local hashedString = sha256.pbkdf2(passwd, 2, 32):toHex()
    insertPasswd.writeLine(hashedString)
    insertPasswd.close()
    print("Thanks, I will save that.")
end
sleep(3)
term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.white)
print("Copying files to local user.")

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
sleep(1)
print("Finished copying files.")
sleep(2)
shell.run("/system/desktop.lua")