if fs.exists("/boot/ccboot/boot.lua") then
    term.clear()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colours.white)
    term.setTextColor(colours.black)
    print("Welcome to CCBoot!")
    sleep(1)
    term.setBackgroundColor(colours.black)
    term.setTextColor(colours.white)
    shell.run("boot/ccboot/boot.lua");
else
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.red)
    print("CCBoot doesn't exist halting...")
    sleep(2)
    os.shutdown()
end
