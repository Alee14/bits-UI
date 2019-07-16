--[[ 
    bits-UI Recovery Script: A script that's going to show you to either reset the computer or transfer files.
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
print("Welcome to the bits-UI recovery mode!")
sleep(2)
print("Do you want to either reset or transfer?")
local input = read();
if input == "reset" then
    shell.run("/system/recovery/reset.lua")
elseif input == "transfer" then
    shell.run("/system/recovery/transfer.lua")
else
    shell.run("/startup.lua")
end