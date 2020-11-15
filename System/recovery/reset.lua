--[[ 
    bits-UI Reset Script: A script that will wipe the system to the default factory settings.
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
function clear()
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.white)
end
clear()
print("Are you sure you want to reset bits-UI? (y/n)")
local input = read()
if input == "y" then
    print("Erasing all user stored data...")
    fs.delete("/home")
    fs.delete("/etc/passwd.pwd")
    sleep(2)
    print("Erased all data...")
    sleep(2)
    print("Rebooting...")
    sleep(3)
    os.reboot()
else
    os.reboot()
end