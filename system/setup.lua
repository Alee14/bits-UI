--[[
    bits-UI Setup: After installation setup for bits-UI
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