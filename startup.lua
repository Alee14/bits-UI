--[[ 
    bits-UI Boot Loader (BUBL): A boot loader for bits-UI
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
local boot = "/system/boot.lua"
local allowUpdate = true

function bootloader()
    term.setCursorPos(1,1)
    print("Welcome to the BUBL boot loader!\n")
    term.setCursorPos(1,3)
    print("1. Boot bits-UI\n")
    term.setCursorPos(1,4)
    print("2. Update bits-UI\n")
    term.setCursorPos(1,5)
    print("3. Boot CraftOS\n")
    term.setCursorPos(1,7)
    term.write("> ")
end

function clear()
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.white)
end

function bootloaderInput()
    local input = read()

    if input == "1" then
        clear()
        shell.run("/system/boot.lua")
    elseif input == "2" then
        clear()
        if allowUpdate == false then
            print("You have set updating to false!\n Please set updating to true if you want to update...")
            sleep(3)
            clear()
            bootloader()
            bootloaderInput()
        else
        print("Running updater...")
        sleep(3)
        shell.run("pastebin", "run", "7XY80hfG")
        end
    elseif input == "3" then
        clear()
        print(os.version())
        term.setCursorPos(1,2)
    else
        print("[ERROR] Invalid number.")
        sleep(2)
        clear()
        bootloader()
        bootloaderInput()
    end
    
end

clear()

if fs.exists(boot) then
    term.setTextColor(colors.green)
    print("Boot detected!")
    sleep(1)
else
    clear()
    term.setTextColor(colors.red)
    print("[ERROR] System has been halted.")
    term.setCursorPos(1,2)
    print("Details: Cannot find boot.lua")  
    sleep(3)
    os.shutdown()  
end

clear()
bootloader()
bootloaderInput()
