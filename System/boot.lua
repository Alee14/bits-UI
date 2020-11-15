--[[
    bits-UI Boot: A boot script for bits-UI.
    Copyright (C) 2020 Alee14

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
]]--

local version = "1.0 Alpha 2"
local desktop = "/system/desktop.lua"

term.clear()
term.setCursorPos(1,1)

print("Starting up bits-UI ".. version .."...")
sleep(1)

print(_HOST)

sleep(1)

if term.isColor() then
    term.setTextColor(colors.green)
    print("[OK] Advanced Computer is detected...")
else
    print("[ERROR] You need a advanced computer in order to make the UI functional...")
    sleep(3)
    os.shutdown()
end

sleep(1)

if fs.exists(desktop) then
    term.setTextColor(colors.green)
    print("[OK] Desktop has been found...")
else
    term.setTextColor(colors.red)
    print("[ERROR] Desktop cannot be found...")
    sleep(2)
    os.shutdown()
end

sleep(1)

if fs.exists("/home") then
    term.setTextColor(colors.green)
    print("[OK] Home has been found...")
else
    fs.makeDir("/Home")
    term.setTextColor(colors.green)
    print("[OK] Home directory has been created...")
end

if fs.exists("/etc") then
    term.setTextColor(colors.green)
    print("[OK] Etc has been found...")
else
    fs.makeDir("/etc")
    term.setTextColor(colors.green)
    print("[OK] Etc directory has been created...")
end

sleep(1)

if fs.exists("/home/.config") then
    term.setTextColor(colors.green)
    print("[OK] Config has been found...")
else
    config = io.open("/home/.config", "w")
    config:close()
    term.setTextColor(colors.blue)
    print("[INFO] Config has not been found!")
    print("[INFO] You will be sent to the post installation setup...")
    sleep(2)
    shell.run("/system/post-setup.lua")
end

sleep(1)
term.setTextColor(colors.green)
print("[DONE] Boot sequence has been completed...")
term.setTextColor(colors.white)
sleep(1)
shell.run(desktop)