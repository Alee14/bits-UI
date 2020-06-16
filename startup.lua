if fs.exists("/boot/ccboot/boot.lua") then
shell.run("boot/ccboot/boot.lua");
else
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.red)
    print("CCBoot doesn't exist halting...")
    sleep(2)
    os.shutdown()
end
