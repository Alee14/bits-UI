--[[ 
    bits-UI Transfer Script: A script that will transfer files from one system to the other.
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
print("Welcome to the bits-UI transfer!")
sleep(2)
if fs.exists("/disk") then
    shell.run("copy", "/home", "/disk")
    shell.run("copy", "/etc/passwd.pwd", "/disk")
else
    print("You need a floppy disk to copy over data.")
    print("Transfer has been halted.")
    sleep(2)
    shell.run("/startup.lua")
end