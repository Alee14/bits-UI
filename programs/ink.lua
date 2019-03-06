tArgs = {...}

if OneOS then
	--running under OneOS
	OneOS.ToolBarColour = colours.grey
	OneOS.ToolBarTextColour = colours.white
end

local _w, _h = term.getSize()

local round = function(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

UIColours = {
	Toolbar = colours.grey,
	ToolbarText = colours.lightGrey,
	ToolbarSelected = colours.lightBlue,
	ControlText = colours.white,
	ToolbarItemTitle = colours.black,
	Background = colours.lightGrey,
	MenuBackground = colours.white,
	MenuText = colours.black,
	MenuSeparatorText = colours.grey,
	MenuDisabledText = colours.lightGrey,
	Shadow = colours.grey,
	TransparentBackgroundOne = colours.white,
	TransparentBackgroundTwo = colours.lightGrey,
	MenuBarActive = colours.white
}

local getNames = peripheral.getNames or function()
	local tResults = {}
	for n,sSide in ipairs( rs.getSides() ) do
		if peripheral.isPresent( sSide ) then
			table.insert( tResults, sSide )
			local isWireless = false
			if not pcall(function()isWireless = peripheral.call(sSide, 'isWireless') end) then
				isWireless = true
			end     
			if peripheral.getType( sSide ) == "modem" and not isWireless then
				local tRemote = peripheral.call( sSide, "getNamesRemote" )
				for n,sName in ipairs( tRemote ) do
					table.insert( tResults, sName )
				end
			end
		end
	end
	return tResults
end

Peripheral = {
	GetPeripheral = function(_type)
		for i, p in ipairs(Peripheral.GetPeripherals()) do
			if p.Type == _type then
				return p
			end
		end
	end,

	Call = function(type, ...)
		local tArgs = {...}
		local p = Peripheral.GetPeripheral(type)
		peripheral.call(p.Side, unpack(tArgs))
	end,

	GetPeripherals = function(filterType)
		local peripherals = {}
		for i, side in ipairs(getNames()) do
			local name = peripheral.getType(side):gsub("^%l", string.upper)
			local code = string.upper(side:sub(1,1))
			if side:find('_') then
				code = side:sub(side:find('_')+1)
			end

			local dupe = false
			for i, v in ipairs(peripherals) do
				if v[1] == name .. ' ' .. code then
					dupe = true
				end
			end

			if not dupe then
				local _type = peripheral.getType(side)
				local isWireless = false
				if _type == 'modem' then
					if not pcall(function()isWireless = peripheral.call(sSide, 'isWireless') end) then
						isWireless = true
					end     
					if isWireless then
						_type = 'wireless_modem'
						name = 'W '..name
					end
				end
				if not filterType or _type == filterType then
					table.insert(peripherals, {Name = name:sub(1,8) .. ' '..code, Fullname = name .. ' ('..side:sub(1, 1):upper() .. side:sub(2, -1)..')', Side = side, Type = _type, Wireless = isWireless})
				end
			end
		end
		return peripherals
	end,

	PresentNamed = function(name)
		return peripheral.isPresent(name)
	end,

	CallType = function(type, ...)
		local tArgs = {...}
		local p = GetPeripheral(type)
		return peripheral.call(p.Side, unpack(tArgs))
	end,

	CallNamed = function(name, ...)
		local tArgs = {...}
		return peripheral.call(name, unpack(tArgs))
	end
}

TextLine = {
	Text = "",
	Alignment = AlignmentLeft,

	Initialise = function(self, text, alignment)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Text = text
		new.Alignment = alignment or AlignmentLeft
		return new
	end
}

local StripColours = function(str)
	return str:gsub('['..string.char(14)..'-'..string.char(29)..']','')
end

Printer = {
	Name = nil,
	PeripheralType = 'printer',

	paperLevel = function(self)
		return Peripheral.CallNamed(self.Name, 'getPaperLevel')
	end,

	newPage = function(self)
		return Peripheral.CallNamed(self.Name, 'newPage')
	end,

	endPage = function(self)
		return Peripheral.CallNamed(self.Name, 'endPage')
	end,

	pageWrite = function(self, text)
		return Peripheral.CallNamed(self.Name, 'write', text)
	end,

	setPageTitle = function(self, title)
		return Peripheral.CallNamed(self.Name, 'setPageTitle', title)
	end,

	inkLevel = function(self)
		return Peripheral.CallNamed(self.Name, 'getInkLevel')
	end,

	getCursorPos = function(self)
		return Peripheral.CallNamed(self.Name, 'getCursorPos')
	end,

	setCursorPos = function(self, x, y)
		return Peripheral.CallNamed(self.Name, 'setCursorPos', x, y)
	end,

	pageSize = function(self)
		return Peripheral.CallNamed(self.Name, 'getPageSize')
	end,

	Present = function()
		if Peripheral.GetPeripheral(Printer.PeripheralType) == nil then
			return false
		else
			return true
		end
	end,

	PrintLines = function(self, lines, title, copies)
		local pages = {}
		local pageLines = {}
		for i, line in ipairs(lines) do
			table.insert(pageLines, TextLine:Initialise(StripColours(line)))
			if i % 25 == 0 then
				table.insert(pages, pageLines)
				pageLines = {}
			end
		end
		if #pageLines ~= 0 then
				table.insert(pages, pageLines)
		end
		return self:PrintPages(pages, title, copies)
	end,

	PrintPages = function(self, pages, title, copies)
		copies = copies or 1
		for c = 1, copies do
			for p, page in ipairs(pages) do
				if self:paperLevel() < #pages * copies then
					return 'Add more paper to the printer'
				end
				if self:inkLevel() < #pages * copies then
					return 'Add more ink to the printer'
				end
				self:newPage()
				for i, line in ipairs(page) do
					self:setCursorPos(1, i)
					self:pageWrite(StripColours(line.Text))
				end
				if title then
					self:setPageTitle(title)
				end
				self:endPage()
			end
		end
	end,

	Initialise = function(self, name)
		if Printer.Present() then --fix
			local new = {}    -- the new instance
			setmetatable( new, {__index = self} )
			if name and Peripheral.PresentNamed(name) then
				new.Name = name
			else
				new.Name = Peripheral.GetPeripheral(Printer.PeripheralType).Side
			end
			return new
		end
	end
}

Clipboard = {
	Content = nil,
	Type = nil,
	IsCut = false,

	Empty = function()
		Clipboard.Content = nil
		Clipboard.Type = nil
		Clipboard.IsCut = false
	end,

	isEmpty = function()
		return Clipboard.Content == nil
	end,

	Copy = function(content, _type)
		Clipboard.Content = content
		Clipboard.Type = _type or 'generic'
		Clipboard.IsCut = false
	end,

	Cut = function(content, _type)
		Clipboard.Content = content
		Clipboard.Type = _type or 'generic'
		Clipboard.IsCut = true
	end,

	Paste = function()
		local c, t = Clipboard.Content, Clipboard.Type
		if Clipboard.IsCut then
			Clipboard.Empty()
		end
		return c, t
	end
}

if OneOS and OneOS.Clipboard then
	Clipboard = OneOS.Clipboard
end

Drawing = {
	
	Screen = {
		Width = _w,
		Height = _h
	},

	DrawCharacters = function (x, y, characters, textColour,bgColour)
		Drawing.WriteStringToBuffer(x, y, characters, textColour, bgColour)
	end,
	
	DrawBlankArea = function (x, y, w, h, colour)
		Drawing.DrawArea (x, y, w, h, " ", 1, colour)
	end,

	DrawArea = function (x, y, w, h, character, textColour, bgColour)
		--width must be greater than 1, other wise we get a stack overflow
		if w < 0 then
			w = w * -1
		elseif w == 0 then
			w = 1
		end

		for ix = 1, w do
			local currX = x + ix - 1
			for iy = 1, h do
				local currY = y + iy - 1
				Drawing.WriteToBuffer(currX, currY, character, textColour, bgColour)
			end
		end
	end,

	DrawImage = function(_x,_y,tImage, w, h)
		if tImage then
			for y = 1, h do
				if not tImage[y] then
					break
				end
				for x = 1, w do
					if not tImage[y][x] then
						break
					end
					local bgColour = tImage[y][x]
		            local textColour = tImage.textcol[y][x] or colours.white
		            local char = tImage.text[y][x]
		            Drawing.WriteToBuffer(x+_x-1, y+_y-1, char, textColour, bgColour)
				end
			end
		elseif w and h then
			Drawing.DrawBlankArea(x, y, w, h, colours.green)
		end
	end,
	--using .nft
	LoadImage = function(path)
		local image = {
			text = {},
			textcol = {}
		}
		local fs = fs
		if OneOS then
			fs = OneOS.FS
		end
		if fs.exists(path) then
			local _open = io.open
			if OneOS then
				_open = OneOS.IO.open
			end
	        local file = _open(path, "r")
	        local sLine = file:read()
	        local num = 1
	        while sLine do  
	                table.insert(image, num, {})
	                table.insert(image.text, num, {})
	                table.insert(image.textcol, num, {})
	                                            
	                --As we're no longer 1-1, we keep track of what index to write to
	                local writeIndex = 1
	                --Tells us if we've hit a 30 or 31 (BG and FG respectively)- next char specifies the curr colour
	                local bgNext, fgNext = false, false
	                --The current background and foreground colours
	                local currBG, currFG = nil,nil
	                for i=1,#sLine do
	                        local nextChar = string.sub(sLine, i, i)
	                        if nextChar:byte() == 30 then
                                bgNext = true
	                        elseif nextChar:byte() == 31 then
                                fgNext = true
	                        elseif bgNext then
                                currBG = Drawing.GetColour(nextChar)
                                bgNext = false
	                        elseif fgNext then
                                currFG = Drawing.GetColour(nextChar)
                                fgNext = false
	                        else
                                if nextChar ~= " " and currFG == nil then
                                       currFG = colours.white
                                end
                                image[num][writeIndex] = currBG
                                image.textcol[num][writeIndex] = currFG
                                image.text[num][writeIndex] = nextChar
                                writeIndex = writeIndex + 1
	                        end
	                end
	                num = num+1
	                sLine = file:read()
	        end
	        file:close()
		end
	 	return image
	end,

	DrawCharactersCenter = function(x, y, w, h, characters, textColour,bgColour)
		w = w or Drawing.Screen.Width
		h = h or Drawing.Screen.Height
		x = x or 0
		y = y or 0
		x = math.ceil((w - #characters) / 2) + x
		y = math.floor(h / 2) + y

		Drawing.DrawCharacters(x, y, characters, textColour, bgColour)
	end,

	GetColour = function(hex)
		if hex == ' ' then
			return colours.transparent
		end
	    local value = tonumber(hex, 16)
	    if not value then return nil end
	    value = math.pow(2,value)
	    return value
	end,

	Clear = function (_colour)
		_colour = _colour or colours.black
		Drawing.ClearBuffer()
		Drawing.DrawBlankArea(1, 1, Drawing.Screen.Width, Drawing.Screen.Height, _colour)
	end,

	Buffer = {},
	BackBuffer = {},

	DrawBuffer = function()
		for y,row in pairs(Drawing.Buffer) do
			for x,pixel in pairs(row) do
				local shouldDraw = true
				local hasBackBuffer = true
				if Drawing.BackBuffer[y] == nil or Drawing.BackBuffer[y][x] == nil or #Drawing.BackBuffer[y][x] ~= 3 then
					hasBackBuffer = false
				end
				if hasBackBuffer and Drawing.BackBuffer[y][x][1] == Drawing.Buffer[y][x][1] and Drawing.BackBuffer[y][x][2] == Drawing.Buffer[y][x][2] and Drawing.BackBuffer[y][x][3] == Drawing.Buffer[y][x][3] then
					shouldDraw = false
				end
				if shouldDraw then
					term.setBackgroundColour(pixel[3])
					term.setTextColour(pixel[2])
					term.setCursorPos(x, y)
					term.write(pixel[1])
				end
			end
		end
		Drawing.BackBuffer = Drawing.Buffer
		Drawing.Buffer = {}
		term.setCursorPos(1,1)
	end,

	ClearBuffer = function()
		Drawing.Buffer = {}
	end,

	WriteStringToBuffer = function (x, y, characters, textColour,bgColour)
		for i = 1, #characters do
   			local character = characters:sub(i,i)
   			Drawing.WriteToBuffer(x + i - 1, y, character, textColour, bgColour)
		end
	end,

	WriteToBuffer = function(x, y, character, textColour,bgColour)
		x = round(x)
		y = round(y)
		if bgColour == colours.transparent then
			Drawing.Buffer[y] = Drawing.Buffer[y] or {}
			Drawing.Buffer[y][x] = Drawing.Buffer[y][x] or {"", colours.white, colours.black}
			Drawing.Buffer[y][x][1] = character
			Drawing.Buffer[y][x][2] = textColour
		else
			Drawing.Buffer[y] = Drawing.Buffer[y] or {}
			Drawing.Buffer[y][x] = {character, textColour, bgColour}
		end
	end,
}

Current = {
	Document = nil,
	TextInput = nil,
	CursorPos = {1,1},
	CursorColour = colours.black,
	Selection = {8, 36},
	Window = nil,
	Modified = false,
}

local isQuitting = false

function OrderSelection()
	if Current.Selection then
		if Current.Selection[1] <= Current.Selection[2] then
			return Current.Selection
		else
			return {Current.Selection[2], Current.Selection[1]}
		end
	end
end

function StripColours(str)
	return str:gsub('['..string.char(14)..'-'..string.char(29)..']','')
end

function FindColours(str)
	local _, count = str:gsub('['..string.char(14)..'-'..string.char(29)..']','')
	return count
end

ColourFromCharacter = function(character)
	local n = character:byte() - 14
	if n > 16 then
		return nil
	else
		return 2^n
	end
end

CharacterFromColour = function(colour)
	return string.char(math.floor(math.log(colour)/math.log(2))+14)
end

Events = {}

Button = {
	X = 1,
	Y = 1,
	Width = 0,
	Height = 0,
	BackgroundColour = colours.lightGrey,
	TextColour = colours.white,
	ActiveBackgroundColour = colours.lightGrey,
	Text = "",
	Parent = nil,
	_Click = nil,
	Toggle = nil,

	AbsolutePosition = function(self)
		return self.Parent:AbsolutePosition()
	end,

	Draw = function(self)
		local bg = self.BackgroundColour
		local tc = self.TextColour
		if type(bg) == 'function' then
			bg = bg()
		end

		if self.Toggle then
			tc = UIColours.MenuBarActive
			bg = self.ActiveBackgroundColour
		end

		local pos = GetAbsolutePosition(self)
		Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, bg)
		Drawing.DrawCharactersCenter(pos.X, pos.Y, self.Width, self.Height, self.Text, tc, bg)
	end,

	Initialise = function(self, x, y, width, height, backgroundColour, parent, click, text, textColour, toggle, activeBackgroundColour)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		height = height or 1
		new.Width = width or #text + 2
		new.Height = height
		new.Y = y
		new.X = x
		new.Text = text or ""
		new.BackgroundColour = backgroundColour or colours.lightGrey
		new.TextColour = textColour or colours.white
		new.ActiveBackgroundColour = activeBackgroundColour or colours.lightGrey
		new.Parent = parent
		new._Click = click
		new.Toggle = toggle
		return new
	end,

	Click = function(self, side, x, y)
		if self._Click then
			if self:_Click(side, x, y, not self.Toggle) ~= false and self.Toggle ~= nil then
				self.Toggle = not self.Toggle
				Draw()
			end
			return true
		else
			return false
		end
	end
}

TextBox = {
	X = 1,
	Y = 1,
	Width = 0,
	Height = 0,
	BackgroundColour = colours.lightGrey,
	TextColour = colours.black,
	Parent = nil,
	TextInput = nil,
	Placeholder = '',

	AbsolutePosition = function(self)
		return self.Parent:AbsolutePosition()
	end,

	Draw = function(self)		
		local pos = GetAbsolutePosition(self)
		Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, self.BackgroundColour)
		local text = self.TextInput.Value
		if #tostring(text) > (self.Width - 2) then
			text = text:sub(#text-(self.Width - 3))
			if Current.TextInput == self.TextInput then
				Current.CursorPos = {pos.X + 1 + self.Width-2, pos.Y}
			end
		else
			if Current.TextInput == self.TextInput then
				Current.CursorPos = {pos.X + 1 + self.TextInput.CursorPos, pos.Y}
			end
		end
		
		if #tostring(text) == 0 then
			Drawing.DrawCharacters(pos.X + 1, pos.Y, self.Placeholder, colours.lightGrey, self.BackgroundColour)
		else
			Drawing.DrawCharacters(pos.X + 1, pos.Y, text, self.TextColour, self.BackgroundColour)
		end

		term.setCursorBlink(true)
		
		Current.CursorColour = self.TextColour
	end,

	Initialise = function(self, x, y, width, height, parent, text, backgroundColour, textColour, done, numerical)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		height = height or 1
		new.Width = width or #text + 2
		new.Height = height
		new.Y = y
		new.X = x
		new.TextInput = TextInput:Initialise(text or '', function(key)
			if done then
				done(key)
			end
			Draw()
		end, numerical)
		new.BackgroundColour = backgroundColour or colours.lightGrey
		new.TextColour = textColour or colours.black
		new.Parent = parent
		return new
	end,

	Click = function(self, side, x, y)
		Current.Input = self.TextInput
		self:Draw()
	end
}

TextInput = {
	Value = "",
	Change = nil,
	CursorPos = nil,
	Numerical = false,
	IsDocument = nil,

	Initialise = function(self, value, change, numerical, isDocument)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Value = tostring(value)
		new.Change = change
		new.CursorPos = #tostring(value)
		new.Numerical = numerical
		new.IsDocument = isDocument or false
		return new
	end,

	Insert = function(self, str)
		if self.Numerical then
			str = tostring(tonumber(str))
		end

		local selection = OrderSelection()

		if self.IsDocument and selection then
			self.Value = string.sub(self.Value, 1, selection[1]-1) .. str .. string.sub( self.Value, selection[2]+2)
			self.CursorPos = selection[1]
			Current.Selection = nil
		else
			local _, newLineAdjust = string.gsub(self.Value:sub(1, self.CursorPos), '\n','')

			self.Value = string.sub(self.Value, 1, self.CursorPos + newLineAdjust) .. str .. string.sub( self.Value, self.CursorPos + 1  + newLineAdjust)
			self.CursorPos = self.CursorPos + 1
		end
		
		self.Change(key)
	end,

	Extract = function(self, remove)
		local selection = OrderSelection()
		if self.IsDocument and selection then
			local _, newLineAdjust = string.gsub(self.Value:sub(selection[1], selection[2]), '\n','')
			local str = string.sub(self.Value, selection[1], selection[2]+1+newLineAdjust)
			if remove then
				self.Value = string.sub(self.Value, 1, selection[1]-1) .. string.sub( self.Value, selection[2]+2+newLineAdjust)
				self.CursorPos = selection[1] - 1
				Current.Selection = nil
			end
			return str
		end
	end,

	Char = function(self, char)
		if char == 'nil' then
			return
		end
		self:Insert(char)
	end,

	Key = function(self, key)
		if key == keys.enter then
			if self.IsDocument then
				self.Value = string.sub(self.Value, 1, self.CursorPos ) .. '\n' .. string.sub( self.Value, self.CursorPos + 1 )
				self.CursorPos = self.CursorPos + 1
			end
			self.Change(key)		
		elseif key == keys.left then
			-- Left
			if self.CursorPos > 0 then
				local colShift = FindColours(string.sub( self.Value, self.CursorPos, self.CursorPos))
				self.CursorPos = self.CursorPos - 1 - colShift
				self.Change(key)
			end
			
		elseif key == keys.right then
			-- Right				
			if self.CursorPos < string.len(self.Value) then
				local colShift = FindColours(string.sub( self.Value, self.CursorPos+1, self.CursorPos+1))
				self.CursorPos = self.CursorPos + 1 + colShift
				self.Change(key)
			end
		
		elseif key == keys.backspace then
			-- Backspace
			if self.IsDocument and Current.Selection then
				self:Extract(true)
				self.Change(key)
			elseif self.CursorPos > 0 then
				local colShift = FindColours(string.sub( self.Value, self.CursorPos, self.CursorPos))
				local _, newLineAdjust = string.gsub(self.Value:sub(1, self.CursorPos), '\n','')

				self.Value = string.sub( self.Value, 1, self.CursorPos - 1 - colShift + newLineAdjust) .. string.sub( self.Value, self.CursorPos + 1 - colShift + newLineAdjust)
				self.CursorPos = self.CursorPos - 1 - colShift
				self.Change(key)
			end
		elseif key == keys.home then
			-- Home
			self.CursorPos = 0
			self.Change(key)
		elseif key == keys.delete then
			if self.IsDocument and Current.Selection then
				self:Extract(true)
				self.Change(key)
			elseif self.CursorPos < string.len(self.Value) then
				self.Value = string.sub( self.Value, 1, self.CursorPos ) .. string.sub( self.Value, self.CursorPos + 2 )				
				self.Change(key)
			end
		elseif key == keys["end"] then
			-- End
			self.CursorPos = string.len(self.Value)
			self.Change(key)
		elseif key == keys.up and self.IsDocument then
			-- Up
			if Current.Document.CursorPos then
				local page = Current.Document.Pages[Current.Document.CursorPos.Page]
				self.CursorPos = page:GetCursorPosFromPoint(Current.Document.CursorPos.Collum + page.MarginX, Current.Document.CursorPos.Line - page.MarginY - 1 + Current.Document.ScrollBar.Scroll, true)
				self.Change(key)
			end
		elseif key == keys.down and self.IsDocument then
			-- Down
			if Current.Document.CursorPos then
				local page = Current.Document.Pages[Current.Document.CursorPos.Page]
				self.CursorPos = page:GetCursorPosFromPoint(Current.Document.CursorPos.Collum + page.MarginX, Current.Document.CursorPos.Line - page.MarginY + 1 + Current.Document.ScrollBar.Scroll, true)
				self.Change(key)
			end
		end
	end
}

Menu = {
	X = 0,
	Y = 0,
	Width = 0,
	Height = 0,
	Owner = nil,
	Items = {},
	RemoveTop = false,

	Draw = function(self)
		Drawing.DrawBlankArea(self.X + 1, self.Y + 1, self.Width, self.Height, UIColours.Shadow)
		if not self.RemoveTop then
			Drawing.DrawBlankArea(self.X, self.Y, self.Width, self.Height, UIColours.MenuBackground)
			for i, item in ipairs(self.Items) do
				if item.Separator then
					Drawing.DrawArea(self.X, self.Y + i, self.Width, 1, '-', colours.grey, UIColours.MenuBackground)
				else
					local textColour = item.Colour or UIColours.MenuText
					if (item.Enabled and type(item.Enabled) == 'function' and item.Enabled() == false) or item.Enabled == false then
						textColour = UIColours.MenuDisabledText
					end
					Drawing.DrawCharacters(self.X + 1, self.Y + i, item.Title, textColour, UIColours.MenuBackground)
				end
			end
		else
			Drawing.DrawBlankArea(self.X, self.Y, self.Width, self.Height, UIColours.MenuBackground)
			for i, item in ipairs(self.Items) do
				if item.Separator then
					Drawing.DrawArea(self.X, self.Y + i - 1, self.Width, 1, '-', colours.grey, UIColours.MenuBackground)
				else
					local textColour = item.Colour or UIColours.MenuText
					if (item.Enabled and type(item.Enabled) == 'function' and item.Enabled() == false) or item.Enabled == false then
						textColour = UIColours.MenuDisabledText
					end
					Drawing.DrawCharacters(self.X + 1, self.Y + i - 1, item.Title, textColour, UIColours.MenuBackground)

					Drawing.DrawCharacters(self.X - 1 + self.Width-#item.KeyName, self.Y + i - 1, item.KeyName, textColour, UIColours.MenuBackground)
				end
			end
		end
	end,

	NameForKey = function(self, key)
		if key == keys.leftCtrl then
			return '^'
		elseif key == keys.tab then
			return 'Tab'
		elseif key == keys.delete then
			return 'Delete'
		elseif key == keys.n then
			return 'N'
		elseif key == keys.a then
			return 'A'
		elseif key == keys.s then
			return 'S'
		elseif key == keys.o then
			return 'O'
		elseif key == keys.z then
			return 'Z'
		elseif key == keys.y then
			return 'Y'
		elseif key == keys.c then
			return 'C'
		elseif key == keys.x then
			return 'X'
		elseif key == keys.v then
			return 'V'
		elseif key == keys.r then
			return 'R'
		elseif key == keys.l then
			return 'L'
		elseif key == keys.t then
			return 'T'
		elseif key == keys.h then
			return 'H'
		elseif key == keys.e then
			return 'E'
		elseif key == keys.p then
			return 'P'
		elseif key == keys.f then
			return 'F'
		elseif key == keys.m then
			return 'M'
		elseif key == keys.q then
			return 'Q'
		else
			return '?'		
		end
	end,

	Initialise = function(self, x, y, items, owner, removeTop)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		if not owner then
			return
		end

		local keyNames = {}

		for i, v in ipairs(items) do
			items[i].KeyName = ''
			if v.Keys then
				for _i, key in ipairs(v.Keys) do
					items[i].KeyName = items[i].KeyName .. self:NameForKey(key)
				end
			end
			if items[i].KeyName ~= '' then
				table.insert(keyNames, items[i].KeyName)
			end
		end
		local keysLength = LongestString(keyNames)
		if keysLength > 0 then
			keysLength = keysLength + 2
		end

		new.Width = LongestString(items, 'Title') + 2 + keysLength
		if new.Width < 10 then
			new.Width = 10
		end
		new.Height = #items + 2
		new.RemoveTop = removeTop or false
		if removeTop then
			new.Height = new.Height - 1
		end
		
		if y < 1 then
			y = 1
		end
		if x < 1 then
			x = 1
		end

		if y + new.Height > Drawing.Screen.Height + 1 then
			y = Drawing.Screen.Height - new.Height
		end
		if x + new.Width > Drawing.Screen.Width + 1 then
			x = Drawing.Screen.Width - new.Width
		end


		new.Y = y
		new.X = x
		new.Items = items
		new.Owner = owner
		return new
	end,

	New = function(self, x, y, items, owner, removeTop)
		if Current.Menu and Current.Menu.Owner == owner then
			Current.Menu = nil
			return
		end

		local new = self:Initialise(x, y, items, owner, removeTop)
		Current.Menu = new
		return new
	end,

	Click = function(self, side, x, y)
		local i = y-1
		if self.RemoveTop then
			i = y
		end
		if i >= 1 and y < self.Height then
			if not ((self.Items[i].Enabled and type(self.Items[i].Enabled) == 'function' and self.Items[i].Enabled() == false) or self.Items[i].Enabled == false) and self.Items[i].Click then
				self.Items[i]:Click()
				if Current.Menu.Owner and Current.Menu.Owner.Toggle then
					Current.Menu.Owner.Toggle = false
				end
				Current.Menu = nil
				self = nil
			end
			return true
		end
	end
}

MenuBar = {
	X = 1,
	Y = 1,
	Width = Drawing.Screen.Width,
	Height = 1,
	MenuBarItems = {},

	AbsolutePosition = function(self)
		return {X = self.X, Y = self.Y}
	end,

	Draw = function(self)
		--Drawing.DrawArea(self.X - 1, self.Y, 1, self.Height, "|", UIColours.ToolbarText, UIColours.Background)

		Drawing.DrawBlankArea(self.X, self.Y, self.Width, self.Height, colours.grey)
		for i, button in ipairs(self.MenuBarItems) do
			button:Draw()
		end
	end,

	Initialise = function(self, items)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.X = 1
		new.Y = 1
		new.MenuBarItems = items
		return new
	end,

	AddToolbarItem = function(self, item)
		table.insert(self.ToolbarItems, item)
		self:CalculateToolbarItemPositions()
	end,

	CalculateToolbarItemPositions = function(self)
		local currY = 1
		for i, toolbarItem in ipairs(self.ToolbarItems) do
			toolbarItem.Y = currY
			currY = currY + toolbarItem.Height
		end
	end,

	Click = function(self, side, x, y)
		for i, item in ipairs(self.MenuBarItems) do
			if item.X <= x and item.X + item.Width > x then
				if item:Click(item, side, x - item.X + 1, 1) then
					return true
				end
			end
		end
		return false
	end
}

TextFormatPlainText = 1
TextFormatInkText = 2

Document = {
	X = 1,
	Y = 1,
	PageSize = {Width = 25, Height = 21},
	TextInput = nil,
	Pages = {},
	Format = TextFormatPlainText,
	Title = '',
	Path = nil,
	ScrollBar = nil,
	Lines = {},
	CursorPos = nil,

	CalculateLineWrapping = function(self)
		local limit = self.PageSize.Width
		local text = self.TextInput.Value
        local lines = {''}
        local words = {}

        for word, space in text:gmatch('(%S+)(%s*)') do
        	for i = 1, math.ceil(#word/limit) do
        		local _space = ''
        		if i == math.ceil(#word/limit) then
        			_space = space
        		end
        		table.insert(words, {word:sub(1+limit*(i-1), limit*i), _space})
        	end
        end

        for i, ws in ipairs(words) do
        		local word = ws[1]
        		local space = ws[2]
                local temp = lines[#lines] .. word .. space:gsub('\n','')
                if #temp > limit then
                    table.insert(lines, '')
                end
                if space:find('\n') then
                    lines[#lines] = lines[#lines] .. word
                    
                    space = space:gsub('\n', function()
                            table.insert(lines, '')
                            return ''
                    end)
                else
                    lines[#lines] = lines[#lines] .. word .. space
                end
        end
        return lines
	end,

	CalculateCursorPos = function(self)
		local passedCharacters = 0
		Current.CursorPos = nil
		for p, page in ipairs(self.Pages) do
			page:Draw()
			if not Current.CursorPos then
				for i, line in ipairs(page.Lines) do
					local relCursor = self.TextInput.CursorPos - FindColours(self.TextInput.Value:sub(1,self.TextInput.CursorPos))
					if passedCharacters + #StripColours(line.Text:gsub('\n','')) >= relCursor then
						Current.CursorPos = {self.X + page.MarginX + (relCursor - passedCharacters), page.Y + 1 + i}
						self.CursorPos = {Page = p, Line = i, Collum = relCursor - passedCharacters - FindColours(self.TextInput.Value:sub(1,self.TextInput.CursorPos-1))}
						break
					end
					passedCharacters = passedCharacters + #StripColours(line.Text:gsub('\n',''))
				end
			end
		end
	end,

	Draw = function(self)
		self:CalculatePages()
		self:CalculateCursorPos()
		self.ScrollBar:Draw()
	end,

	CalculatePages = function(self)
		self.Pages = {}
		local lines = self:CalculateLineWrapping()
		self.Lines = lines
		local pageLines = {}
		local totalPageHeight = (3 + self.PageSize.Height + 2 * Page.MarginY)
		for i, line in ipairs(lines) do
			table.insert(pageLines, TextLine:Initialise(line))
			if i % self.PageSize.Height == 0 then
				table.insert(self.Pages, Page:Initialise(self, pageLines, 3 - self.ScrollBar.Scroll + totalPageHeight*(#self.Pages)))
				pageLines = {}
			end
		end
		if #pageLines ~= 0 then
			table.insert(self.Pages, Page:Initialise(self, pageLines, 3 - self.ScrollBar.Scroll + totalPageHeight*(#self.Pages)))
		end

		self.ScrollBar.MaxScroll = totalPageHeight*(#self.Pages) - Drawing.Screen.Height + 1
	end,

	ScrollToCursor = function(self)
		self:CalculateCursorPos()
		if Current.CursorPos and 
			(Current.CursorPos[2] > Drawing.Screen.Height 
			or Current.CursorPos[2] < 2) then
			self.ScrollBar:DoScroll(Current.CursorPos[2] - Drawing.Screen.Height)
		end
	end,

	SetSelectionColour = function(self, colour)
		local selection = OrderSelection()
		local text = self.TextInput:Extract(true)
		local colChar = CharacterFromColour(colour)
		local precedingColour = ''
		if FindColours(self.TextInput.Value:sub(self.TextInput.CursorPos+1, self.TextInput.CursorPos+1)) == 0 then
			for i = 1, self.TextInput.CursorPos do
				local c = self.TextInput.Value:sub(self.TextInput.CursorPos - i,self.TextInput.CursorPos - i)
				if FindColours(c) == 1 then
					precedingColour = c
					break
				end
			end
			if precedingColour == '' then
				precedingColour = CharacterFromColour(colours.black)
			end
		end

		self.TextInput:Insert(colChar..StripColours(text)..precedingColour)
		--text = text:gsub('['..string.char(14)..'-'..string.char(29)..']','')
	end,

	Initialise = function(self, text, title, path)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Title = title or 'New Document'
		new.Path = path
		new.X = (Drawing.Screen.Width - (new.PageSize.Width + 2*(Page.MarginX)))/2
		new.Y = 2
		new.TextInput = TextInput:Initialise(text, function()
			new:ScrollToCursor() 
			Current.Modified = true
			Draw()
		end, false, true)
		new.ScrollBar = ScrollBar:Initialise(Drawing.Screen.Width, new.Y, Drawing.Screen.Height-1, 0, nil, nil, nil, function()end)
		Current.TextInput = new.TextInput
		Current.ScrollBar = new.ScrollBar
		return new
	end
}

ScrollBar = {
	X = 1,
	Y = 1,
	Width = 1,
	Height = 1,
	BackgroundColour = colours.grey,
	BarColour = colours.lightBlue,
	Parent = nil,
	Change = nil,
	Scroll = 0,
	MaxScroll = 0,
	ClickPoint = nil,

	AbsolutePosition = function(self)
		return self.Parent:AbsolutePosition()
	end,

	Draw = function(self)
		local pos = GetAbsolutePosition(self)
	    local barHeight = self.Height - self.MaxScroll
	    if barHeight < 3 then
	      barHeight = 3
	    end
	    local percentage = (self.Scroll/self.MaxScroll)

	    Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, self.BackgroundColour)
	    Drawing.DrawBlankArea(pos.X, pos.Y + round(self.Height*percentage - barHeight*percentage), self.Width, barHeight, self.BarColour)
	end,

	Initialise = function(self, x, y, height, maxScroll, backgroundColour, barColour, parent, change)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Width = 1
		new.Height = height
		new.Y = y
		new.X = x
		new.BackgroundColour = backgroundColour or colours.grey
		new.BarColour = barColour or colours.lightBlue
		new.Parent = parent
		new.Change = change or function()end
		new.MaxScroll = maxScroll
		new.Scroll = 0
		return new
	end,

	DoScroll = function(self, amount)
		amount = round(amount)
		if self.Scroll < 0 or self.Scroll > self.MaxScroll then
			return false
		end
		self.Scroll = self.Scroll + amount
		if self.Scroll < 0 then
			self.Scroll = 0
		elseif self.Scroll > self.MaxScroll then
			self.Scroll = self.MaxScroll
		end
		self.Change()
		return true
	end,

	Click = function(self, side, x, y, drag)
		local percentage = (self.Scroll/self.MaxScroll)
		local barHeight = (self.Height - self.MaxScroll)
		if barHeight < 3 then
			barHeight = 3
		end
		local relScroll = (self.MaxScroll*(y + barHeight*percentage)/self.Height)
		if not drag then
			self.ClickPoint = self.Scroll - relScroll + 1
		end

		if self.Scroll-1 ~= relScroll then
			self:DoScroll(relScroll-self.Scroll-1 + self.ClickPoint)
		end
		return true
	end
}

AlignmentLeft = 1
AlignmentCentre = 2
AlignmentRight = 3

TextLine = {
	Text = "",
	Alignment = AlignmentLeft,

	Initialise = function(self, text, alignment)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Text = text
		new.Alignment = alignment or AlignmentLeft
		return new
	end
}

local clickPos = 1
Page = {
	X = 1,
	Y = 1,
	Width = 1,
	Height = 1,
	MarginX = 3,
	MarginY = 2,
	BackgroundColour = colours.white,
	TextColour = colours.white,
	ActiveBackgroundColour = colours.lightGrey,
	Lines = {},
	Parent = nil,

	AbsolutePosition = function(self)
		return self.Parent:AbsolutePosition()
	end,

	Draw = function(self)
		local pos = GetAbsolutePosition(self)

		if pos.Y > Drawing.Screen.Height or pos.Y + self.Height < 1 then
			return
		end

		Drawing.DrawBlankArea(pos.X+self.Width,pos.Y -1 + 1, 1, self.Height, UIColours.Shadow)
		Drawing.DrawBlankArea(pos.X+1, pos.Y -1 + self.Height, self.Width, 1, UIColours.Shadow)
		Drawing.DrawBlankArea(pos.X, pos.Y -1, self.Width, self.Height, self.BackgroundColour)

		local textColour = self.TextColour
		if not Current.Selection then
			for i, line in ipairs(self.Lines) do
				local _c = 1
				for c = 1, #line.Text do
					local col = ColourFromCharacter(line.Text:sub(c,c))
					if col then
						textColour = col
					else
						Drawing.WriteToBuffer(pos.X + self.MarginX - 1 + _c, pos.Y -2 + i + self.MarginY, line.Text:sub(c,c), textColour, self.BackgroundColour)
						_c = _c + 1
					end
				end
			end
		else
			local selection = OrderSelection()
			local char = 1
			local textColour = self.TextColour
			for i, line in ipairs(self.Lines) do
				local _c = 1
				for c = 1, #line.Text do
					local col = ColourFromCharacter(line.Text:sub(c,c))
					if col then
						textColour = col
					else
						local tc = textColour
						local colour = colours.white
						if char >= selection[1] and char <= selection[2] then
							colour = colours.lightBlue
							tc = colours.white
						end

						Drawing.WriteToBuffer(pos.X + self.MarginX - 1 + _c, pos.Y -2 + i + self.MarginY, line.Text:sub(c,c), tc, colour)
						_c = _c + 1
					end
					char = char + 1
				end
			end
		end
	end,

	Initialise = function(self, parent, lines, y)
		local new = {}    -- the new instanc
		setmetatable( new, {__index = self} )
		new.Height = parent.PageSize.Height + 2 * self.MarginY
		new.Width = parent.PageSize.Width + 2 * self.MarginX
		new.X = 1
		new.Y = y or 1
		new.Lines = lines or {}
		new.BackgroundColour = colours.white
		new.TextColour = colours.black
		new.Parent = parent
		new.ClickPos = 1
		return new
	end,

	GetCursorPosFromPoint = function(self, x, y, rel)
		local pos = GetAbsolutePosition(self)
		if rel then
			pos = {Y = 0, X = 0}
		end
		local row = y - pos.Y + self.MarginY - self.Parent.ScrollBar.Scroll
		local col = x - self.MarginX - pos.X + 1
		local cursorPos = 0
		if row <= 0 or col <= 0 then
			return 0
		end

		if row > #self.Lines then
			for i, v in ipairs(self.Lines) do
				cursorPos = cursorPos + #v.Text-- - FindColours(v.Text)
			end
			return cursorPos
		end

		--term.setCursorPos(1,3)
		local prevLineCount = 0
		for i, v in ipairs(self.Lines) do
			if i == row then
				if col > #v.Text then
					col = #v.Text-- + FindColours(v.Text)
				else
					col = col + FindColours(v.Text:sub(1, col))
				end
				--term.setCursorPos(1,2)
				--print(prevLineCount)
				cursorPos = cursorPos + col + 2 - i - prevLineCount
				break
			else
				prevLineCount = FindColours(v.Text)
				if prevLineCount ~= 0 then
					prevLineCount = prevLineCount
				end
				cursorPos = cursorPos + #v.Text + 2 - i + FindColours(v.Text)
			end
		end

		return cursorPos - 2
	end,

	Click = function(self, side, x, y, drag)
		local cursorPos = self:GetCursorPosFromPoint(x, y)
		self.Parent.TextInput.CursorPos = cursorPos
		if drag == nil then
			Current.Selection = nil
			clickPos = x
		else
			local relCursor = cursorPos-- - FindColours(self.Parent.TextInput.Value:sub(1,cursorPos)) + 1
			if not Current.Selection then
				local adder = 1
				if clickPos and clickPos < x then
					adder = 0
				end
				Current.Selection = {relCursor + adder, relCursor + 1 + adder}
			else
				Current.Selection[2] = relCursor + 1
			end
		end
		Draw()
		return true
	end
}

function GetAbsolutePosition(object)
	local obj = object
	local i = 0
	local x = 1
	local y = 1
	while true do
		x = x + obj.X - 1
		y = y + obj.Y - 1

		if not obj.Parent then
			return {X = x, Y = y}
		end

		obj = obj.Parent

		if i > 32 then
			return {X = 1, Y = 1}
		end

		i = i + 1
	end

end

function Draw()
	if not Current.Window then
		Drawing.Clear(colours.lightGrey)
	else
		Drawing.DrawArea(1, 2, Drawing.Screen.Width, Drawing.Screen.Height, '|', colours.black, colours.lightGrey)
	end

	if Current.Document then
		Current.Document:Draw()
	end

	Current.MenuBar:Draw()

	if Current.Window then
		Current.Window:Draw()
	end

	if Current.Menu then
		Current.Menu:Draw()
	end

	Drawing.DrawBuffer()

	if Current.TextInput and Current.CursorPos and not Current.Menu and not(Current.Window and Current.Document and Current.TextInput == Current.Document.TextInput) and Current.CursorPos[2] > 1 then
		term.setCursorPos(Current.CursorPos[1], Current.CursorPos[2])
		term.setCursorBlink(true)
		term.setTextColour(Current.CursorColour)
	else
		term.setCursorBlink(false)
	end
end
MainDraw = Draw

LongestString = function(input, key)
	local length = 0
	for i = 1, #input do
		local value = input[i]
		if key then
			if value[key] then
				value = value[key]
			else
				value = ''
			end
		end
		local titleLength = string.len(value)
		if titleLength > length then
			length = titleLength
		end
	end
	return length
end

function LoadMenuBar()
	Current.MenuBar = MenuBar:Initialise({
		Button:Initialise(1, 1, nil, nil, colours.grey, Current.MenuBar, function(self, side, x, y, toggle)
			if toggle then
				Menu:New(1, 2, {
					{
						Title = "New...",
						Click = function()
							Current.Document = Document:Initialise('')							
						end,
						Keys = {
							keys.leftCtrl,
							keys.n
						}
					},
					{
						Title = 'Open...',
						Click = function()
							DisplayOpenDocumentWindow()
						end,
						Keys = {
							keys.leftCtrl,
							keys.o
						}
					},
					{
						Separator = true
					},
					{
						Title = 'Save...',
						Click = function()
							SaveDocument()
						end,
						Keys = {
							keys.leftCtrl,
							keys.s
						},
						Enabled = function()
							return true
						end
					},
					{
						Separator = true
					},
					{
						Title = 'Print...',
						Click = function()
							PrintDocument()
						end,
						Keys = {
							keys.leftCtrl,
							keys.p
						},
						Enabled = function()
							return true
						end
					},
					{
						Separator = true
					},
					{
						Title = 'Quit',
						Click = function()
							Close()
						end
					},
			--[[
					{
						Title = 'Save As...',
						Click = function()

						end
					}	
			]]--
				}, self, true)
			else
				Current.Menu = nil
			end
			return true 
		end, 'File', colours.lightGrey, false),
		Button:Initialise(7, 1, nil, nil, colours.grey, Current.MenuBar, function(self, side, x, y, toggle)
			if not self.Toggle then
				Menu:New(7, 2, {
			--[[
					{
						Title = "Undo",
						Click = function()
						end,
						Keys = {
							keys.leftCtrl,
							keys.z
						},
						Enabled = function()
							return false
						end
					},
					{
						Title = 'Redo',
						Click = function()
							
						end,
						Keys = {
							keys.leftCtrl,
							keys.y
						},
						Enabled = function()
							return false
						end
					},
					{
						Separator = true
					},
			]]--
					{
						Title = 'Cut',
						Click = function()
							Clipboard.Cut(Current.Document.TextInput:Extract(true), 'text')
						end,
						Keys = {
							keys.leftCtrl,
							keys.x
						},
						Enabled = function()
							return Current.Document ~= nil and Current.Selection and Current.Selection[1] and Current.Selection[2] ~= nil
						end
					},
					{
						Title = 'Copy',
						Click = function()
							Clipboard.Copy(Current.Document.TextInput:Extract(), 'text')
						end,
						Keys = {
							keys.leftCtrl,
							keys.c
						},
						Enabled = function()
							return Current.Document ~= nil and Current.Selection and Current.Selection[1] and Current.Selection[2] ~= nil
						end
					},
					{
						Title = 'Paste',
						Click = function()
							local paste = Clipboard.Paste()
							Current.Document.TextInput:Insert(paste)
							Current.Document.TextInput.CursorPos = Current.Document.TextInput.CursorPos + #paste - 1
						end,
						Keys = {
							keys.leftCtrl,
							keys.v
						},
						Enabled = function()
							return Current.Document ~= nil and (not Clipboard.isEmpty()) and Clipboard.Type == 'text'
						end
					},
					{
						Separator = true,	
					},
					{
						Title = 'Select All',
						Click = function()
							Current.Selection = {1, #Current.Document.TextInput.Value:gsub('\n','')}
						end,
						Keys = {
							keys.leftCtrl,
							keys.a
						},
						Enabled = function()
							return Current.Document ~= nil
						end
					}
				}, self, true)
			else
				Current.Menu = nil
			end
			return true 
		end, 'Edit', colours.lightGrey, false)
	})
end

function LoadMenuBar()
	Current.MenuBar = MenuBar:Initialise({
		Button:Initialise(1, 1, nil, nil, colours.grey, Current.MenuBar, function(self, side, x, y, toggle)
			if toggle then
				Menu:New(1, 2, {
					{
						Title = "New...",
						Click = function()
							Current.Document = Document:Initialise('')							
						end,
						Keys = {
							keys.leftCtrl,
							keys.n
						}
					},
					{
						Title = 'Open...',
						Click = function()
							DisplayOpenDocumentWindow()
						end,
						Keys = {
							keys.leftCtrl,
							keys.o
						}
					},
					{
						Separator = true
					},
					{
						Title = 'Save...',
						Click = function()
							SaveDocument()
						end,
						Keys = {
							keys.leftCtrl,
							keys.s
						},
						Enabled = function()
							return Current.Document ~= nil
						end
					},
					{
						Separator = true
					},
					{
						Title = 'Print...',
						Click = function()
							PrintDocument()
						end,
						Keys = {
							keys.leftCtrl,
							keys.p
						},
						Enabled = function()
							return true
						end
					},
					{
						Separator = true
					},
					{
						Title = 'Quit',
						Click = function()
							if Close() and OneOS then
								OneOS.Close()
							end
						end,
						Keys = {
							keys.leftCtrl,
							keys.q
						}
					},
			--[[
					{
						Title = 'Save As...',
						Click = function()

						end
					}	
			]]--
				}, self, true)
			else
				Current.Menu = nil
			end
			return true 
		end, 'File', colours.lightGrey, false),
		Button:Initialise(7, 1, nil, nil, colours.grey, Current.MenuBar, function(self, side, x, y, toggle)
			if not self.Toggle then
				Menu:New(7, 2, {
			--[[
					{
						Title = "Undo",
						Click = function()
						end,
						Keys = {
							keys.leftCtrl,
							keys.z
						},
						Enabled = function()
							return false
						end
					},
					{
						Title = 'Redo',
						Click = function()
							
						end,
						Keys = {
							keys.leftCtrl,
							keys.y
						},
						Enabled = function()
							return false
						end
					},
					{
						Separator = true
					},
			]]--
					{
						Title = 'Cut',
						Click = function()
							Clipboard.Cut(Current.Document.TextInput:Extract(true), 'text')
						end,
						Keys = {
							keys.leftCtrl,
							keys.x
						},
						Enabled = function()
							return Current.Document ~= nil and Current.Selection and Current.Selection[1] and Current.Selection[2] ~= nil
						end
					},
					{
						Title = 'Copy',
						Click = function()
							Clipboard.Copy(Current.Document.TextInput:Extract(), 'text')
						end,
						Keys = {
							keys.leftCtrl,
							keys.c
						},
						Enabled = function()
							return Current.Document ~= nil and Current.Selection and Current.Selection[1] and Current.Selection[2] ~= nil
						end
					},
					{
						Title = 'Paste',
						Click = function()
							local paste = Clipboard.Paste()
							Current.Document.TextInput:Insert(paste)
							Current.Document.TextInput.CursorPos = Current.Document.TextInput.CursorPos + #paste - 1
						end,
						Keys = {
							keys.leftCtrl,
							keys.v
						},
						Enabled = function()
							return Current.Document ~= nil and (not Clipboard.isEmpty()) and Clipboard.Type == 'text'
						end
					},
					{
						Separator = true,	
					},
					{
						Title = 'Select All',
						Click = function()
							Current.Selection = {1, #Current.Document.TextInput.Value:gsub('\n','')}
						end,
						Keys = {
							keys.leftCtrl,
							keys.a
						},
						Enabled = function()
							return Current.Document ~= nil
						end
					}
				}, self, true)
			else
				Current.Menu = nil
			end
			return true 
		end, 'Edit', colours.lightGrey, false),
		Button:Initialise(13, 1, nil, nil, colours.grey, Current.MenuBar, function(self, side, x, y, toggle)
			if not self.Toggle then
				Menu:New(13, 2, {
					{
						Title = 'Red',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.red,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					},
					{
						Title = 'Orange',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.orange,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					},
					{
						Title = 'Yellow',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.yellow,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					},
					{
						Title = 'Pink',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.pink,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					},
					{
						Title = 'Magenta',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.magenta,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					},
					{
						Title = 'Purple',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.purple,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					},
					{
						Title = 'Light Blue',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.lightBlue,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					},
					{
						Title = 'Cyan',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.cyan,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					},
					{
						Title = 'Blue',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.blue,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					},
					{
						Title = 'Green',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.green,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					},
					{
						Title = 'Light Grey',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.lightGrey,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					},
					{
						Title = 'Grey',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.grey,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					},
					{
						Title = 'Black',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.black,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					},
					{
						Title = 'Brown',
						Click = function(item)
							Current.Document:SetSelectionColour(item.Colour)
						end,
						Colour = colours.brown,
						Enabled = function()
							return (Current.Document ~= nil and Current.Selection ~= nil and Current.Selection[1] ~= nil and Current.Selection[2] ~= nil)
						end
					}
				}, self, true)
			else
				Current.Menu = nil
			end
			return true 
		end, 'Colour', colours.lightGrey, false)
	})
end

function SplashScreen()
	local w = colours.white
	local b = colours.black
	local u = colours.blue
	local lb = colours.lightBlue
	local splashIcon = {{w,w,w,b,w,w,w,b,w,w,w,},{w,w,w,b,w,w,w,b,w,w,w,},{w,w,w,b,u,u,u,b,w,w,w,},{w,b,b,u,u,u,u,u,b,b,w,},{b,u,u,lb,lb,u,u,u,u,u,b,},{b,u,lb,lb,u,u,u,u,u,u,b,},{b,u,lb,lb,u,u,u,u,u,u,b,},{b,u,u,u,u,u,u,u,u,u,b,},{w,b,b,b,b,b,b,b,b,b,w,},
	["text"]={{" "," "," "," "," "," "," "," "," "," "," ",},{" "," "," "," "," "," "," "," "," "," "," ",},{" "," "," "," "," "," "," "," "," "," "," ",},{" "," "," "," "," "," "," "," "," "," "," ",},{" "," "," "," "," "," "," "," "," "," "," ",},{" "," "," "," ","I","n","k"," "," "," "," ",},{" "," "," "," "," "," "," "," "," "," "," ",},{" "," ","b","y"," ","o","e","e","d"," "," "},{" "," "," "," "," "," "," "," "," "," "," ",},},
	["textcol"]={{w,w,w,w,w,w,w,w,w,w,w,},{w,w,w,w,w,w,w,w,w,w,w,},{w,w,w,w,w,w,w,w,w,w,w,},{w,w,w,w,w,w,w,w,w,w,w,},{w,w,w,w,w,w,w,w,w,w,w,},{w,w,w,w,w,w,w,w,w,w,w,},{w,w,w,w,w,w,w,w,w,w,w,},{lb,lb,lb,lb,lb,lb,lb,lb,lb,lb,lb,},{w,w,w,w,w,w,w,w,w,w,w,},},}
	Drawing.Clear(colours.white)
	Drawing.DrawImage((Drawing.Screen.Width - 11)/2, (Drawing.Screen.Height - 9)/2, splashIcon, 11, 9)
	Drawing.DrawBuffer()
	Drawing.Clear(colours.black)
	parallel.waitForAny(function()sleep(1)end, function()os.pullEvent('mouse_click')end)
end

function Initialise(arg)
	if OneOS then
		fs = OneOS.FS
	end

	if not OneOS then
		SplashScreen()
	end
	EventRegister('mouse_click', TryClick)
	EventRegister('mouse_drag', function(event, side, x, y)TryClick(event, side, x, y, true)end)
	EventRegister('mouse_scroll', Scroll)
	EventRegister('key', HandleKey)
	EventRegister('char', HandleKey)
	EventRegister('timer', Timer)
	EventRegister('terminate', function(event) if Close() then error( "Terminated", 0 ) end end)
	
	LoadMenuBar()

	--Current.Document = Document:Initialise('abcdefghijklmnopqrtuvwxy')--'Hello everybody!')
	if tArgs[1] then
		if fs.exists(tArgs[1]) then
			OpenDocument(tArgs[1])
		else
			--new
		end
	else
		Current.Document = Document:Initialise('')--'Hello everybody!')
	end

	--[[
	if arg and fs.exists(arg) then
			OpenDocument(arg)
		else
			DisplayNewDocumentWindow()
		end
	]]--
	Draw()

	EventHandler()
end

local isControlPushed = false
controlPushedTimer = nil
closeWindowTimer = nil
function Timer(event, timer)
	if timer == closeWindowTimer then
		if Current.Window then
			Current.Window:Close()
		end
		Draw()
	elseif timer == controlPushedTimer then
		isControlPushed = false
	end
end

local ignoreNextChar = false
function HandleKey(...)
	local args = {...}
	local event = args[1]
	local keychar = args[2]
																							--Mac left command character
	if event == 'key' and keychar == keys.leftCtrl or keychar == keys.rightCtrl or keychar == 219 then
		isControlPushed = true
		controlPushedTimer = os.startTimer(0.5)
	elseif isControlPushed then
		if event == 'key' then
			if CheckKeyboardShortcut(keychar) then
				isControlPushed = false
				ignoreNextChar = true
			end
		end
	elseif ignoreNextChar then
		ignoreNextChar = false
	elseif Current.TextInput then
		if event == 'char' then
			Current.TextInput:Char(keychar)
		elseif event == 'key' then
			Current.TextInput:Key(keychar)
		end
	end
end

function CheckKeyboardShortcut(key)
	local shortcuts = {}
	shortcuts[keys.n] = function() Current.Document = Document:Initialise('') end
	shortcuts[keys.o] = function() DisplayOpenDocumentWindow() end
	shortcuts[keys.s] = function() if Current.Document ~= nil then SaveDocument() end end
	shortcuts[keys.left] = function() if Current.TextInput then Current.TextInput:Key(keys.home) end end
	shortcuts[keys.right] = function() if Current.TextInput then Current.TextInput:Key(keys["end"]) end end
--	shortcuts[keys.q] = function() DisplayOpenDocumentWindow() end
	if Current.Document ~= nil then
		shortcuts[keys.s] = function() SaveDocument() end
		shortcuts[keys.p] = function() PrintDocument() end
		if Current.Selection and Current.Selection[1] and Current.Selection[2] ~= nil then
			shortcuts[keys.x] = function() Clipboard.Cut(Current.Document.TextInput:Extract(true), 'text') end
			shortcuts[keys.c] = function() Clipboard.Copy(Current.Document.TextInput:Extract(), 'text') end
		end
		if (not Clipboard.isEmpty()) and Clipboard.Type == 'text' then
			shortcuts[keys.v] = function() local paste = Clipboard.Paste()
									Current.Document.TextInput:Insert(paste)
									Current.Document.TextInput.CursorPos = Current.Document.TextInput.CursorPos + #paste - 1
								end
		end
		shortcuts[keys.a] = function() Current.Selection = {1, #Current.Document.TextInput.Value:gsub('\n','')} end
	end
							
	if shortcuts[key] then
		shortcuts[key]()
		Draw()
		return true
	else
		return false
	end
end

--[[
	Check if the given object falls under the click coordinates
]]--
function CheckClick(object, x, y)
	if object.X <= x and object.Y <= y and object.X + object.Width > x and object.Y + object.Height > y then
		return true
	end
end

--[[
	Attempt to clicka given object
]]--
function DoClick(object, side, x, y, drag)
	local obj = GetAbsolutePosition(object)
	obj.Width = object.Width
	obj.Height = object.Height
	if object and CheckClick(obj, x, y) then
		return object:Click(side, x - object.X + 1, y - object.Y + 1, drag)
	end	
end

--[[
	Try to click at the given coordinates
]]--
function TryClick(event, side, x, y, drag)
	if Current.Menu then
		if DoClick(Current.Menu, side, x, y, drag) then
			Draw()
			return
		else
			if Current.Menu.Owner and Current.Menu.Owner.Toggle then
				Current.Menu.Owner.Toggle = false
			end
			Current.Menu = nil
			Draw()
			return
		end
	elseif Current.Window then
		if DoClick(Current.Window, side, x, y, drag) then
			Draw()
			return
		else
			Current.Window:Flash()
			return
		end
	end
	local interfaceElements = {}

	table.insert(interfaceElements, Current.MenuBar)
	table.insert(interfaceElements, Current.ScrollBar)
	for i, page in ipairs(Current.Document.Pages) do
		table.insert(interfaceElements, page)
	end

	for i, object in ipairs(interfaceElements) do
		if DoClick(object, side, x, y, drag) then
			Draw()
			return
		end		
	end
	Draw()
end

function Scroll(event, direction, x, y)
	if Current.Window and Current.Window.OpenButton then
		Current.Document.Scroll = Current.Document.Scroll + direction
		if Current.Window.Scroll < 0 then
			Current.Window.Scroll = 0
		elseif Current.Window.Scroll > Current.Window.MaxScroll then
			Current.Window.Scroll = Current.Window.MaxScroll
		end
		Draw()
	elseif Current.ScrollBar then
		if Current.ScrollBar:DoScroll(direction*2) then
			Draw()
		end
	end
end


--[[
	Registers functions to run on certain events
]]--
function EventRegister(event, func)
	if not Events[event] then
		Events[event] = {}
	end

	table.insert(Events[event], func)
end

--[[
	The main loop event handler, runs registered event functinos
]]--
function EventHandler()
	while true do
		local event, arg1, arg2, arg3, arg4 = os.pullEventRaw()
		if Events[event] then
			for i, e in ipairs(Events[event]) do
				e(event, arg1, arg2, arg3, arg4)
			end
		end
	end
end


local function Extension(path, addDot)
	if not path then
		return nil
	elseif not string.find(fs.getName(path), '%.') then
		if not addDot then
			return fs.getName(path)
		else
			return ''
		end
	else
		local _path = path
		if path:sub(#path) == '/' then
			_path = path:sub(1,#path-1)
		end
		local extension = _path:gmatch('%.[0-9a-z]+$')()
		if extension then
			extension = extension:sub(2)
		else
			--extension = nil
			return ''
		end
		if addDot then
			extension = '.'..extension
		end
		return extension:lower()
	end
end

local RemoveExtension = function(path)
	if path:sub(1,1) == '.' then
		return path
	end
	local extension = Extension(path)
	if extension == path then
		return fs.getName(path)
	end
	return string.gsub(path, extension, ''):sub(1, -2)
end

local acknowledgedColour = false
function PrintDocument()
	if OneOS then
		OneOS.LoadAPI('/System/API/Helpers.lua')
		OneOS.LoadAPI('/System/API/Peripheral.lua')
		OneOS.LoadAPI('/System/API/Printer.lua')
	end

	local doPrint = function()
		local window = PrintDocumentWindow:Initialise():Show()
	end

	if Peripheral.GetPeripheral('printer') == nil then
		ButtonDialougeWindow:Initialise('No Printer Found', 'Please place a printer next to your computer. Ensure you also insert dye (left slot) and paper (top slots)', 'Ok', nil, function(window, ok)
			window:Close()
		end):Show()
	elseif not acknowledgedColour and FindColours(Current.Document.TextInput.Value) ~= 0 then
		ButtonDialougeWindow:Initialise('Important', 'Due to the way printers work, you can\'t print in more than one colour. The dye you use will be the colour of the text.', 'Ok', nil, function(window, ok)
			acknowledgedColour = true
			window:Close()
			doPrint()
		end):Show()
	else
		doPrint()
	end
end

function SaveDocument()
	local function save()
		local h = fs.open(Current.Document.Path, 'w')
		if h then
			if Current.Document.Format == TextFormatPlainText then
				h.write(Current.Document.TextInput.Value)
			else
				local lines = {}
				for p, page in ipairs(Current.Document.Pages) do
					for i, line in ipairs(page.Lines) do
						table.insert(lines, line)
					end
				end
				h.write(textutils.serialize(lines))
			end
			Current.Modified = false
		else
			ButtonDialougeWindow:Initialise('Error', 'An error occured while saving the file, try again.', 'Ok', nil, function(window, ok)
				window:Close()
			end):Show()
		end
		h.close()
	end

	if not Current.Document.Path then
		SaveDocumentWindow:Initialise(function(self, success, path)
			self:Close()
			if success then
				local extension = ''
				if Current.Document.Format == TextFormatPlainText then
					extension = '.txt'
				elseif Current.Document.Format == TextFormatInkText then
					extension = '.ink'
				end
				
				if path:sub(-4) ~= extension then
					path = path .. extension
				end

				Current.Document.Path = path
				Current.Document.Title = fs.getName(path)
				save()
			end
			if Current.Document then
				Current.TextInput = Current.Document.TextInput
			end
		end):Show()
	else
		save()
	end
end

function DisplayOpenDocumentWindow()
	OpenDocumentWindow:Initialise(function(self, success, path)
		self:Close()
		if success then
			OpenDocument(path)
		end
	end):Show()
end

function OpenDocument(path)
	Current.Selection = nil
	local h = fs.open(path, 'r')
	if h then
		Current.Document = Document:Initialise(h.readAll(), RemoveExtension(fs.getName(path)), path)
	else
		ButtonDialougeWindow:Initialise('Error', 'An error occured while opening the file, try again.', 'Ok', nil, function(window, ok)
			window:Close()
			if Current.Document then
				Current.TextInput = Current.Document.TextInput
			end
		end):Show()
	end
	h.close()
end

local TidyPath = function(path)
	path = '/'..path
	local fs = fs
	if OneOS then
		fs = OneOS.FS
	end
	if fs.isDir(path) then
		path = path .. '/'
	end

	path, n = path:gsub("//", "/")
	while n > 0 do
		path, n = path:gsub("//", "/")
	end
	return path
end

OpenDocumentWindow = {
	X = 1,
	Y = 1,
	Width = 0,
	Height = 0,
	CursorPos = 1,
	Visible = true,
	Return = nil,
	OpenButton = nil,
	PathTextBox = nil,
	CurrentDirectory = '/',
	Scroll = 0,
	MaxScroll = 0,
	GoUpButton = nil,
	SelectedFile = '',
	Files = {},
	Typed = false,

	AbsolutePosition = function(self)
		return {X = self.X, Y = self.Y}
	end,

	Draw = function(self)
		if not self.Visible then
			return
		end
		Drawing.DrawBlankArea(self.X + 1, self.Y+1, self.Width, self.Height, colours.grey)
		Drawing.DrawBlankArea(self.X, self.Y, self.Width, 3, colours.lightGrey)
		Drawing.DrawBlankArea(self.X, self.Y+1, self.Width, self.Height-6, colours.white)
		Drawing.DrawCharactersCenter(self.X, self.Y, self.Width, 1, self.Title, colours.black, colours.lightGrey)
		Drawing.DrawBlankArea(self.X, self.Y + self.Height - 5, self.Width, 5, colours.lightGrey)
		self:DrawFiles()

		if (fs.exists(self.PathTextBox.TextInput.Value)) or (self.SelectedFile and #self.SelectedFile > 0 and fs.exists(self.CurrentDirectory .. self.SelectedFile)) then
			self.OpenButton.TextColour = colours.black
		else
			self.OpenButton.TextColour = colours.lightGrey
		end

		self.PathTextBox:Draw()
		self.OpenButton:Draw()
		self.CancelButton:Draw()
		self.GoUpButton:Draw()
	end,

	DrawFiles = function(self)
		for i, file in ipairs(self.Files) do
			if i > self.Scroll and i - self.Scroll <= 11 then
				if file == self.SelectedFile then
					Drawing.DrawCharacters(self.X + 1, self.Y + i - self.Scroll, file, colours.white, colours.lightBlue)
				elseif string.find(file, '%.txt') or string.find(file, '%.text') or string.find(file, '%.ink') or fs.isDir(self.CurrentDirectory .. file) then
					Drawing.DrawCharacters(self.X + 1, self.Y + i - self.Scroll, file, colours.black, colours.white)
				else
					Drawing.DrawCharacters(self.X + 1, self.Y + i - self.Scroll, file, colours.grey, colours.white)
				end
			end
		end
		self.MaxScroll = #self.Files - 11
		if self.MaxScroll < 0 then
			self.MaxScroll = 0
		end
	end,

	Initialise = function(self, returnFunc)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Width = 32
		new.Height = 17
		new.Return = returnFunc
		new.X = math.ceil((Drawing.Screen.Width - new.Width) / 2)
		new.Y = math.ceil((Drawing.Screen.Height - new.Height) / 2)
		new.Title = 'Open Document'
		new.Visible = true
		new.CurrentDirectory = '/'
		new.SelectedFile = nil
		if OneOS and fs.exists('/Desktop/Documents/') then
			new.CurrentDirectory = '/Desktop/Documents/'
		end
		new.OpenButton = Button:Initialise(new.Width - 6, new.Height - 1, nil, nil, colours.white, new, function(self, side, x, y, toggle)
			if fs.exists(new.PathTextBox.TextInput.Value) and self.TextColour == colours.black and not fs.isDir(new.PathTextBox.TextInput.Value) then
				returnFunc(new, true, TidyPath(new.PathTextBox.TextInput.Value))
			elseif new.SelectedFile and self.TextColour == colours.black and fs.isDir(new.CurrentDirectory .. new.SelectedFile) then
				new:GoToDirectory(new.CurrentDirectory .. new.SelectedFile)
			elseif new.SelectedFile and self.TextColour == colours.black then
				returnFunc(new, true, TidyPath(new.CurrentDirectory .. '/' .. new.SelectedFile))
			end
		end, 'Open', colours.black)
		new.CancelButton = Button:Initialise(new.Width - 15, new.Height - 1, nil, nil, colours.white, new, function(self, side, x, y, toggle)
			returnFunc(new, false)
		end, 'Cancel', colours.black)
		new.GoUpButton = Button:Initialise(2, new.Height - 1, nil, nil, colours.white, new, function(self, side, x, y, toggle)
			local folderName = fs.getName(new.CurrentDirectory)
			local parentDirectory = new.CurrentDirectory:sub(1, #new.CurrentDirectory-#folderName-1)
			new:GoToDirectory(parentDirectory)
		end, 'Go Up', colours.black)
		new.PathTextBox = TextBox:Initialise(2, new.Height - 3, new.Width - 2, 1, new, new.CurrentDirectory, colours.white, colours.black)
		new:GoToDirectory(new.CurrentDirectory)
		return new
	end,

	Show = function(self)
		Current.Window = self
		return self
	end,

	Close = function(self)
		Current.Input = nil
		Current.Window = nil
		self = nil
	end,

	GoToDirectory = function(self, path)
		path = TidyPath(path)
		self.CurrentDirectory = path
		self.Scroll = 0
		self.SelectedFile = nil
		self.Typed = false
		self.PathTextBox.TextInput.Value = path
		local fs = fs
		if OneOS then
			fs = OneOS.FS
		end
		self.Files = fs.list(self.CurrentDirectory)
		Draw()
	end,

	Flash = function(self)
		self.Visible = false
		Draw()
		sleep(0.15)
		self.Visible = true
		Draw()
		sleep(0.15)
		self.Visible = false
		Draw()
		sleep(0.15)
		self.Visible = true
		Draw()
	end,

	Click = function(self, side, x, y)
		local items = {self.OpenButton, self.CancelButton, self.PathTextBox, self.GoUpButton}
		local found = false
		for i, v in ipairs(items) do
			if CheckClick(v, x, y) then
				v:Click(side, x, y)
				found = true
			end
		end

		if not found then
			if y <= 12 then
				local fs = fs
				if OneOS then
					fs = OneOS.FS
				end
				self.SelectedFile = fs.list(self.CurrentDirectory)[y-1]
				self.PathTextBox.TextInput.Value = TidyPath(self.CurrentDirectory .. '/' .. self.SelectedFile)
				Draw()
			end
		end
		return true
	end
}

PrintDocumentWindow = {
	X = 1,
	Y = 1,
	Width = 0,
	Height = 0,
	CursorPos = 1,
	Visible = true,
	Return = nil,
	PrintButton = nil,
	CopiesTextBox = nil,
	Scroll = 0,
	MaxScroll = 0,
	PrinterSelectButton = nil,
	Title = '',
	Status = 0, --0 = neutral, 1 = good, -1 = error
	StatusText = '',
	SelectedPrinter = nil,

	AbsolutePosition = function(self)
		return {X = self.X, Y = self.Y}
	end,

	Draw = function(self)
		if not self.Visible then
			return
		end
		Drawing.DrawBlankArea(self.X + 1, self.Y+1, self.Width, self.Height, colours.grey)
		Drawing.DrawBlankArea(self.X, self.Y, self.Width, 1, colours.lightGrey)
		Drawing.DrawBlankArea(self.X, self.Y+1, self.Width, self.Height-1, colours.white)
		Drawing.DrawCharactersCenter(self.X, self.Y, self.Width, 1, self.Title, colours.black, colours.lightGrey)
		
		self.PrinterSelectButton:Draw()
		Drawing.DrawCharactersCenter(self.X,  self.Y + self.PrinterSelectButton.Y - 2, self.Width, 1, 'Printer', colours.black, colours.white)
		Drawing.DrawCharacters(self.X + self.Width - 3, self.Y + self.PrinterSelectButton.Y - 1, '\\/', colours.black, colours.lightGrey)
		Drawing.DrawCharacters(self.X + 1, self.Y + self.CopiesTextBox.Y - 1, 'Copies', colours.black, colours.white)
		local statusColour = colours.grey
		if self.Status == -1 then
			statusColour = colours.red
		elseif self.Status == 1 then
			statusColour = colours.green
		end
		Drawing.DrawCharacters(self.X + 1, self.Y + self.CopiesTextBox.Y + 1, self.StatusText, statusColour, colours.white)

		self.CopiesTextBox:Draw()
		self.PrintButton:Draw()
		self.CancelButton:Draw()
	end,

	Initialise = function(self)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Width = 32
		new.Height = 11
		new.Return = returnFunc
		new.X = math.ceil((Drawing.Screen.Width - new.Width) / 2)
		new.Y = math.ceil((Drawing.Screen.Height - new.Height) / 2)
		new.Title = 'Print Document'
		new.Visible = true
		new.PrintButton = Button:Initialise(new.Width - 7, new.Height - 1, nil, nil, colours.lightGrey, new, function(self, side, x, y, toggle)
			local doPrint = true
			if new.SelectedPrinter == nil then
				local p = Peripheral.GetPeripheral('printer')
				if p then
					new.SelectedPrinter = p.Side
					new.PrinterSelectButton.Text = p.Fullname
				else
					new.StatusText = 'No Connected Printer'
					new.Status = -1
					doPrint = false
				end
			end
			if doPrint then
				local printer = Printer:Initialise(new.SelectedPrinter)
				local err = printer:PrintLines(Current.Document.Lines, Current.Document.Title, tonumber(new.CopiesTextBox.TextInput.Value))
				if not err then
					new.StatusText = 'Document Printed!'
					new.Status = 1
					closeWindowTimer = os.startTimer(1)
				else
					new.StatusText = err
					new.Status = -1
				end
			end
		end, 'Print', colours.black)
		new.CancelButton = Button:Initialise(new.Width - 15, new.Height - 1, nil, nil, colours.lightGrey, new, function(self, side, x, y, toggle)
			new:Close()
			Draw()
		end, 'Close', colours.black)
		new.PrinterSelectButton = Button:Initialise(2, 4, new.Width - 2, nil, colours.lightGrey, new, function(self, side, x, y, toggle)
			local printers = {
					{
						Title = "Automatic",
						Click = function()
							new.SelectedPrinter = nil
							new.PrinterSelectButton.Text = 'Automatic'
						end
					},
					{
						Separator = true
					}
				}
			for i, p in ipairs(Peripheral.GetPeripherals('printer')) do
				table.insert(printers, {
					Title = p.Fullname,
					Click = function(self)
						new.SelectedPrinter = p.Side
						new.PrinterSelectButton.Text = p.Fullname
					end
				})
			end
			Current.Menu = Menu:New(x, y+4, printers, self, true)
		end, 'Automatic', colours.black)
		new.CopiesTextBox = TextBox:Initialise(9, 6, 4, 1, new, 1, colours.lightGrey, colours.black, nil, true)
		Current.TextInput = new.CopiesTextBox.TextInput
		new.StatusText = 'Waiting...'
		new.Status = 0
		return new
	end,

	Show = function(self)
		Current.Window = self
		return self
	end,

	Close = function(self)
		Current.Input = nil
		Current.Window = nil
		self = nil
	end,

	Flash = function(self)
		self.Visible = false
		Draw()
		sleep(0.15)
		self.Visible = true
		Draw()
		sleep(0.15)
		self.Visible = false
		Draw()
		sleep(0.15)
		self.Visible = true
		Draw()
	end,

	Click = function(self, side, x, y)
		local items = {self.PrintButton, self.CancelButton, self.CopiesTextBox, self.PrinterSelectButton}
		for i, v in ipairs(items) do
			if CheckClick(v, x, y) then
				v:Click(side, x, y)
			end
		end
		return true
	end
}

SaveDocumentWindow = {
	X = 1,
	Y = 1,
	Width = 0,
	Height = 0,
	CursorPos = 1,
	Visible = true,
	Return = nil,
	SaveButton = nil,
	PathTextBox = nil,
	CurrentDirectory = '/',
	Scroll = 0,
	MaxScroll = 0,
	ScrollBar = nil,
	GoUpButton = nil,
	Files = {},
	Typed = false,

	AbsolutePosition = function(self)
		return {X = self.X, Y = self.Y}
	end,

	Draw = function(self)
		if not self.Visible then
			return
		end
		Drawing.DrawBlankArea(self.X + 1, self.Y+1, self.Width, self.Height, colours.grey)
		Drawing.DrawBlankArea(self.X, self.Y, self.Width, 3, colours.lightGrey)
		Drawing.DrawBlankArea(self.X, self.Y+1, self.Width, self.Height-6, colours.white)
		Drawing.DrawCharactersCenter(self.X, self.Y, self.Width, 1, self.Title, colours.black, colours.lightGrey)
		Drawing.DrawBlankArea(self.X, self.Y + self.Height - 5, self.Width, 5, colours.lightGrey)
		Drawing.DrawCharacters(self.X + 1, self.Y + self.Height - 5, self.CurrentDirectory, colours.grey, colours.lightGrey)
		self:DrawFiles()

		if (self.PathTextBox.TextInput.Value) then
			self.SaveButton.TextColour = colours.black
		else
			self.SaveButton.TextColour = colours.lightGrey
		end

		self.PathTextBox:Draw()
		self.SaveButton:Draw()
		self.CancelButton:Draw()
		self.GoUpButton:Draw()
	end,

	DrawFiles = function(self)
		for i, file in ipairs(self.Files) do
			if i > self.Scroll and i - self.Scroll <= 10 then
				if file == self.SelectedFile then
					Drawing.DrawCharacters(self.X + 1, self.Y + i - self.Scroll, file, colours.white, colours.lightBlue)
				elseif fs.isDir(self.CurrentDirectory .. file) then
					Drawing.DrawCharacters(self.X + 1, self.Y + i - self.Scroll, file, colours.black, colours.white)
				else
					Drawing.DrawCharacters(self.X + 1, self.Y + i - self.Scroll, file, colours.lightGrey, colours.white)
				end
			end
		end
		self.MaxScroll = #self.Files - 11
		if self.MaxScroll < 0 then
			self.MaxScroll = 0
		end
	end,

	Initialise = function(self, returnFunc)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Width = 32
		new.Height = 16
		new.Return = returnFunc
		new.X = math.ceil((Drawing.Screen.Width - new.Width) / 2)
		new.Y = math.ceil((Drawing.Screen.Height - new.Height) / 2)
		new.Title = 'Save Document'
		new.Visible = true
		new.CurrentDirectory = '/'
		if OneOS and fs.exists('/Desktop/Documents/') then
			new.CurrentDirectory = '/Desktop/Documents/'
		end
		new.SaveButton = Button:Initialise(new.Width - 6, new.Height - 1, nil, nil, colours.white, new, function(self, side, x, y, toggle)
			if self.TextColour == colours.black and not fs.isDir(new.CurrentDirectory ..'/' .. new.PathTextBox.TextInput.Value) then
				returnFunc(new, true, TidyPath(new.CurrentDirectory ..'/' .. new.PathTextBox.TextInput.Value))
			elseif new.SelectedFile and self.TextColour == colours.black and fs.isDir(new.CurrentDirectory .. new.SelectedFile) then
				new:GoToDirectory(new.CurrentDirectory .. new.SelectedFile)
			end
		end, 'Save', colours.black)
		new.CancelButton = Button:Initialise(new.Width - 15, new.Height - 1, nil, nil, colours.white, new, function(self, side, x, y, toggle)
			returnFunc(new, false)
		end, 'Cancel', colours.black)
		new.GoUpButton = Button:Initialise(2, new.Height - 1, nil, nil, colours.white, new, function(self, side, x, y, toggle)
			local folderName = fs.getName(new.CurrentDirectory)
			local parentDirectory = new.CurrentDirectory:sub(1, #new.CurrentDirectory-#folderName-1)
			new:GoToDirectory(parentDirectory)
		end, 'Go Up', colours.black)
		new.PathTextBox = TextBox:Initialise(2, new.Height - 3, new.Width - 2, 1, new, '', colours.white, colours.black, function(key)
			if key == keys.enter then
				new.SaveButton:Click()
			end
		end)
		new.PathTextBox.Placeholder = 'Document Name'
		Current.TextInput = new.PathTextBox.TextInput
		new:GoToDirectory(new.CurrentDirectory)
		return new
	end,

	Show = function(self)
		Current.Window = self
		return self
	end,

	Close = function(self)
		Current.Input = nil
		Current.Window = nil
		self = nil
	end,

	GoToDirectory = function(self, path)
		path = TidyPath(path)
		self.CurrentDirectory = path
		self.Scroll = 0
		self.Typed = false
		local fs = fs
		if OneOS then
			fs = OneOS.FS
		end
		self.Files = fs.list(self.CurrentDirectory)
		Draw()
	end,

	Flash = function(self)
		self.Visible = false
		Draw()
		sleep(0.15)
		self.Visible = true
		Draw()
		sleep(0.15)
		self.Visible = false
		Draw()
		sleep(0.15)
		self.Visible = true
		Draw()
	end,

	Click = function(self, side, x, y)
		local items = {self.SaveButton, self.CancelButton, self.PathTextBox, self.GoUpButton}
		local found = false
		for i, v in ipairs(items) do
			if CheckClick(v, x, y) then
				v:Click(side, x, y)
				found = true
			end
		end

		if not found then
			if y <= 11 then
				local files = fs.list(self.CurrentDirectory)
				if files[y-1] then
					self:GoToDirectory(self.CurrentDirectory..files[y-1])
					Draw()
				end
			end
		end
		return true
	end
}

local WrapText = function(text, maxWidth)
	local lines = {''}
    for word, space in text:gmatch('(%S+)(%s*)') do
            local temp = lines[#lines] .. word .. space:gsub('\n','')
            if #temp > maxWidth then
                    table.insert(lines, '')
            end
            if space:find('\n') then
                    lines[#lines] = lines[#lines] .. word
                    
                    space = space:gsub('\n', function()
                            table.insert(lines, '')
                            return ''
                    end)
            else
                    lines[#lines] = lines[#lines] .. word .. space
            end
    end
	return lines
end

ButtonDialougeWindow = {
	X = 1,
	Y = 1,
	Width = 0,
	Height = 0,
	CursorPos = 1,
	Visible = true,
	CancelButton = nil,
	OkButton = nil,
	Lines = {},

	AbsolutePosition = function(self)
		return {X = self.X, Y = self.Y}
	end,

	Draw = function(self)
		if not self.Visible then
			return
		end
		Drawing.DrawBlankArea(self.X + 1, self.Y+1, self.Width, self.Height, colours.grey)
		Drawing.DrawBlankArea(self.X, self.Y, self.Width, 1, colours.lightGrey)
		Drawing.DrawBlankArea(self.X, self.Y+1, self.Width, self.Height-1, colours.white)
		Drawing.DrawCharactersCenter(self.X, self.Y, self.Width, 1, self.Title, colours.black, colours.lightGrey)

		for i, text in ipairs(self.Lines) do
			Drawing.DrawCharacters(self.X + 1, self.Y + 1 + i, text, colours.black, colours.white)
		end

		self.OkButton:Draw()
		if self.CancelButton then
			self.CancelButton:Draw()
		end
	end,

	Initialise = function(self, title, message, okText, cancelText, returnFunc)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Width = 28
		new.Lines = WrapText(message, new.Width - 2)
		new.Height = 5 + #new.Lines
		new.Return = returnFunc
		new.X = math.ceil((Drawing.Screen.Width - new.Width) / 2)
		new.Y = math.ceil((Drawing.Screen.Height - new.Height) / 2)
		new.Title = title
		new.Visible = true
		new.Visible = true
		new.OkButton = Button:Initialise(new.Width - #okText - 2, new.Height - 1, nil, 1, nil, new, function()
			returnFunc(new, true)
		end, okText)
		if cancelText then
			new.CancelButton = Button:Initialise(new.Width - #okText - 2 - 1 - #cancelText - 2, new.Height - 1, nil, 1, nil, new, function()
				returnFunc(new, false)
			end, cancelText)
		end

		return new
	end,

	Show = function(self)
		Current.Window = self
		return self
	end,

	Close = function(self)
		Current.Window = nil
		self = nil
	end,

	Flash = function(self)
		self.Visible = false
		Draw()
		sleep(0.15)
		self.Visible = true
		Draw()
		sleep(0.15)
		self.Visible = false
		Draw()
		sleep(0.15)
		self.Visible = true
		Draw()
	end,

	Click = function(self, side, x, y)
		local items = {self.OkButton, self.CancelButton}
		local found = false
		for i, v in ipairs(items) do
			if CheckClick(v, x, y) then
				v:Click(side, x, y)
				found = true
			end
		end
		return true
	end
}

TextDialougeWindow = {
	X = 1,
	Y = 1,
	Width = 0,
	Height = 0,
	CursorPos = 1,
	Visible = true,
	CancelButton = nil,
	OkButton = nil,
	Lines = {},
	TextInput = nil,

	AbsolutePosition = function(self)
		return {X = self.X, Y = self.Y}
	end,

	Draw = function(self)
		if not self.Visible then
			return
		end
		Drawing.DrawBlankArea(self.X + 1, self.Y+1, self.Width, self.Height, colours.grey)
		Drawing.DrawBlankArea(self.X, self.Y, self.Width, 1, colours.lightGrey)
		Drawing.DrawBlankArea(self.X, self.Y+1, self.Width, self.Height-1, colours.white)
		Drawing.DrawCharactersCenter(self.X, self.Y, self.Width, 1, self.Title, colours.black, colours.lightGrey)

		for i, text in ipairs(self.Lines) do
			Drawing.DrawCharacters(self.X + 1, self.Y + 1 + i, text, colours.black, colours.white)
		end


		Drawing.DrawBlankArea(self.X + 1, self.Y + self.Height - 4, self.Width - 2, 1, colours.lightGrey)
		Drawing.DrawCharacters(self.X + 2, self.Y + self.Height - 4, self.TextInput.Value, colours.black, colours.lightGrey)
		Current.CursorPos = {self.X + 2 + self.TextInput.CursorPos, self.Y + self.Height - 4}
		Current.CursorColour = colours.black

		self.OkButton:Draw()
		if self.CancelButton then
			self.CancelButton:Draw()
		end
	end,

	Initialise = function(self, title, message, okText, cancelText, returnFunc, numerical)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Width = 28
		new.Lines = WrapText(message, new.Width - 2)
		new.Height = 7 + #new.Lines
		new.Return = returnFunc
		new.X = math.ceil((Drawing.Screen.Width - new.Width) / 2)
		new.Y = math.ceil((Drawing.Screen.Height - new.Height) / 2)
		new.Title = title
		new.Visible = true
		new.Visible = true
		new.OkButton = Button:Initialise(new.Width - #okText - 2, new.Height - 1, nil, 1, nil, new, function()
			if #new.TextInput.Value > 0 then
				returnFunc(new, true, new.TextInput.Value)
			end
		end, okText)
		if cancelText then
			new.CancelButton = Button:Initialise(new.Width - #okText - 2 - 1 - #cancelText - 2, new.Height - 1, nil, 1, nil, new, function()
				returnFunc(new, false)
			end, cancelText)
		end
		new.TextInput = TextInput:Initialise('', function(enter)
			if enter then
				new.OkButton:Click()
			end
			Draw()
		end, numerical)

		Current.Input = new.TextInput

		return new
	end,

	Show = function(self)
		Current.Window = self
		return self
	end,

	Close = function(self)
		Current.Window = nil
		Current.Input = nil
		self = nil
	end,

	Flash = function(self)
		self.Visible = false
		Draw()
		sleep(0.15)
		self.Visible = true
		Draw()
		sleep(0.15)
		self.Visible = false
		Draw()
		sleep(0.15)
		self.Visible = true
		Draw()
	end,

	Click = function(self, side, x, y)
		local items = {self.OkButton, self.CancelButton}
		local found = false
		for i, v in ipairs(items) do
			if CheckClick(v, x, y) then
				v:Click(side, x, y)
				found = true
			end
		end
		return true
	end
}

function PrintCentered(text, y)
    local w, h = term.getSize()
    x = math.ceil(math.ceil((w / 2) - (#text / 2)), 0)+1
    term.setCursorPos(x, y)
    print(text)
end

function DoVanillaClose()
	term.setBackgroundColour(colours.black)
	term.setTextColour(colours.white)
	term.clear()
	term.setCursorPos(1, 1)
	PrintCentered("Thanks for using Ink!", (Drawing.Screen.Height/2)-1)
	term.setTextColour(colours.lightGrey)
	PrintCentered("Word Proccessor for ComputerCraft", (Drawing.Screen.Height/2))
	term.setTextColour(colours.white)
	PrintCentered("(c) oeed 2014", (Drawing.Screen.Height/2)+3)
	term.setCursorPos(1, Drawing.Screen.Height)
	error('', 0)
end

function Close()
	if isQuitting or not Current.Document or not Current.Modified then
		if not OneOS then
			DoVanillaClose()
		end
		return true
	else
		local _w = ButtonDialougeWindow:Initialise('Quit Ink?', 'You have unsaved changes, do you want to quit anyway?', 'Quit', 'Cancel', function(window, success)
			if success then
				if OneOS then
					OneOS.Close(true)
				else
					DoVanillaClose()
				end
			end
			window:Close()
			Draw()
		end):Show()
		--it's hacky but it works
		os.queueEvent('mouse_click', 1, _w.X, _w.Y)
		return false
	end
end

if OneOS then
	OneOS.CanClose = function()
		return Close()
	end
end

Initialise()