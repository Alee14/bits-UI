--[[ 
    bits-UI Update: A boot loader for bits-UI
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
local gitMode = false
if fs.exists("/.git") then
    gitMode = true
else
    gitMode = false
end
if gitMode == true then
    print("NOTICE: A git folder has been found...\n\nWhich means that you cannot use the built-in updater, you must use Git to update.\n")
    print("Command for updating via git: \"git pull\"")
    sleep(5)
    os.reboot()
else
print("Running the updater...")
sleep(1)
shell.run("pastebin", "run", "7XY80hfG")
end
