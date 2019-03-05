
-- bits-UI: An operating system for ComputerCraft. Licensed with GPL-3.0.

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

if fs.exists("/system/bitUI.config") then
    term.setTextColor(colors.green)
    print("[OK] Config has been found...")
else
    config = io.open("/system/bitUI.config", "w")
    config:close()
    term.setTextColor(colors.blue)
    print("[INFO] Config has not been found!")
    print("[INFO] You will be sent to the OOBE setup...")
end

sleep(3)
term.setTextColor(colors.green)
print("[DONE] Boot sequence is completed...")
term.setTextColor(colors.white)
sleep(3)
shell.run(desktop)