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
local bublcfg = "/boot/bubl.cfg"
local bVersion = "0.2"
local devMode = false

function bootloader()
    term.setCursorPos(1,1)
    print("Welcome to the BUBL boot loader!\n")
    term.setCursorPos(1,2)
    if fs.exists("/.git") then
    print("Version ".. bVersion .. "-DEV")
    else
    print("Version ".. bVersion)
    end
    term.setCursorPos(1,4)
    print("1. Boot bits-UI\n")
    term.setCursorPos(1,5)
    print("2. Update bits-UI\n")
    term.setCursorPos(1,6)
    print("3. Recovery Mode\n")
    term.setCursorPos(1,7)
    print("4. Boot CraftOS with MBS\n")
    term.setCursorPos(1,9)
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
        print("Loading bits-UI...")
        sleep(1)
        clear()
        if fs.exists(boot) then
            shell.run("/system/boot.lua")
        else
            clear()
            term.setTextColor(colors.red)
            print("[ERROR] System has been halted.")
            term.setCursorPos(1,2)
            print("Details: Cannot find boot.lua")  
            sleep(2)
            os.shutdown()  
        end
    elseif input == "2" then
        clear()
        if devMode == true then
            print("Developer mode is set to true!\n Which means that you cannot update, you must use github to update.")
            sleep(2)
            clear()
            bootloader()
            bootloaderInput()
        else
        print("Running the updater...")
        sleep(1)
        shell.run("pastebin", "run", "7XY80hfG")
        end
    elseif input == "3" then
        clear()
        print("Running Recovery Mode...")
        sleep(1)
        shell.run("/system/recovery/main.lua")
    elseif input == "4" then
        clear()
        sleep(1)
        assert(loadfile("/.mbs/bin/mbs.lua", _ENV))('startup')
        term.setTextColor(16)
        print(os.version() .. " (+MBS)")
        term.setCursorPos(1,2)
        term.setTextColor(1)
    else
        print("[ERROR] Invalid number.")
        sleep(1)
        clear()
        bootloader()
        bootloaderInput()
    end
    
end
clear()
print("Welcome to BUBL!")
sleep(1)
if fs.exists("/.git") then
    devMode = true
else
    devMode = false
end
clear()
bootloader()
bootloaderInput()
