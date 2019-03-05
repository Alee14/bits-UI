
-- bits-UI: An operating system for ComputerCraft. Licensed with GPL-3.0.

local version = "1.0 Alpha 1"
local desktop = "/system/desktop.lua"

term.clear()
term.setCursorPos(1,1)

term.write("Starting up bits-UI ".. version .."...")
sleep(3)

if term.isColor() then
    term.setTextColor(colors.green)
    term.write("[OK] Advanced Computer is detected...")
else
    term.write("[ERROR] You need a advanced computer in order to make the UI functional...")
    sleep(3)
    os.shutdown()
end

sleep(3)

if fs.exists(desktop) then
    term.setTextColor(colors.green)
    term.write("[OK] Desktop has been found...")
else
    term.setTextColor(colors.red)
    term.write("[ERROR] Desktop cannot be found...")
    sleep(3)
    os.shutdown()
end

sleep(3)

if fs.exists("/home") then
    term.setTextColor(colors.green)
    term.write("[OK] Home has been found...")
else
    fs.makeDir("/home")
    term.setTextColor(colors.green)
    term.write("[OK] Home directory has been created...")
end

sleep(3)

if fs.exists("/system/bitUI.config") then
    term.setTextColor(colors.green)
    term.write("[OK] Config has been found...")
else
    config = io.open("/system/bitUI.config", "w")
    config:close()
    term.setTextColor(colors.blue)
    term.write("[INFO] Config has not been found!")
    term.write("[INFO] You will be sent to the OOBE setup...")
end

sleep(3)
term.setTextColor(colors.green)
term.write("[DONE] Boot sequence is completed...")
term.setTextColor(colors.white)
sleep(3)
shell.run(desktop)