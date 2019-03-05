-- bits-UI: An operating system for ComputerCraft. Licensed with GPL-3.0.

function titleBar()  	
    local time = os.time()
    local formattedTime = textutils.formatTime(time, false)
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.green)
    term.setTextColor(1)
    term.clearLine()
    term.setCursorPos(2, 1)
    print("[Apps]")
    term.setCursorPos(44, 1)
    print(formattedTime)
  end

function drawDesktop()
    term.setBackgroundColor(colors.black)
    term.clear()
    titleBar()
end

drawDesktop()

while true do
local event, button, X, Y = os.pullEventRaw()
drawDesktop()
end