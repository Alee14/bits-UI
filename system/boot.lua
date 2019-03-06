--[[
    bits-UI Boot: A boot script for bits-UI.
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

local version = "1.0 Alpha 2"
local desktop = "/system/desktop.lua"

term.clear()
term.setCursorPos(1,1)

print("Starting up bits-UI ".. version .."...")
sleep(3)

if term.isColor() then
    term.setTextColor(colors.green)
    print("[OK] Advanced Computer is detected...")
else
    print("[ERROR] You need a advanced computer in order to make the UI functional...")
    sleep(3)
    os.shutdown()
end

sleep(3)

if fs.exists(desktop) then
    term.setTextColor(colors.green)
    print("[OK] Desktop has been found...")
else
    term.setTextColor(colors.red)
    print("[ERROR] Desktop cannot be found...")
    sleep(3)
    os.shutdown()
end

sleep(3)

if fs.exists("/home") then
    term.setTextColor(colors.green)
    print("[OK] Home has been found...")
else
    fs.makeDir("/home")
    term.setTextColor(colors.green)
    print("[OK] Home directory has been created...")
end

sleep(3)

if fs.exists("/home/.config") then
    term.setTextColor(colors.green)
    print("[OK] Config has been found...")
else
    config = io.open("/home/.config", "w")
    config:close()
    term.setTextColor(colors.blue)
    print("[INFO] Config has not been found!")
    print("[INFO] You will be sent to the post installation setup...")
    sleep(3)
    shell.run("/system/post-setup.lua")
end

sleep(3)
term.setTextColor(colors.green)
print("[DONE] Boot sequence is completed...")
term.setTextColor(colors.white)
sleep(3)
shell.run(desktop)