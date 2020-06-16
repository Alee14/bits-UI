--[[ 
    bits-UI Update: A boot loader for bits-UI
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
local devMode = false
if fs.exists("/.git") then
    devMode = true
else
    devMode = false
end
if devMode == true then
    print("Developer mode is set to true!\nWhich means that you cannot update, you must use github to update.")
    sleep(2)
    os.reboot()
else
print("Running the updater...")
sleep(1)
shell.run("pastebin", "run", "7XY80hfG")
end