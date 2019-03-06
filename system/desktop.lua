--[[
    bits-UI Desktop: A Desktop for bits-UI
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