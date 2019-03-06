--[[
	fLib by NDFJay
]]--
function exists(path)
	local file = assert(io.open(path, "r"))
	if file ~= nil then
		file:close()
		return true
	end
	
	return false
end

function getTable(path)
	if exists(path) then
		local file = io.open(path, "r")
		local lines = {}
		local i = 1
		local line = file:read("*l")
		while line ~= nil do
			lines[i] = line
			line = file:read("*l")
			i = i + 1
		end
		file:close()
		return lines
	end
	return {}
end

function getLine(path, n)
	if exists(path) then
		local lines = getTable(path)
		return lines[n]
	end
	return ""
end

function getText(path)
	if exists(path) then
		local file = assert(io.open(path, "r"))
		return file:read("*a")
	end
	return ""
end

function fappend(path, text)
	local file = assert(io.open(path, "a"))
	file:write(text.."\n")
	file:close()
end 

function fwrite(path, text)
	local file = assert(io.open(path, "w"))
	file:write(text)
	file:close()
end

function fwriteAtStart(path, text)
	local _text = getText(path)
	fwrite(path, text.."\n".._text)
end

function fwriteFromTable(path, t)
	local text = ""
	for _, line in pairs(t) do
		text = text..line.."\n"
	end
	fwrite(path, text)
end

function fappendFromTable(path, t)
	local text = ""
	for _, line in pairs(t) do
		text = text..line.."\n"
	end
	fappend(path, text)
end 

function fwriteAtStartFromTable(path, t)
	local text = ""
	for _, line in pairs(t) do
		text = text..line.."\n"
	end
	fwriteAtStart(path, text)
end

function replaceLine(path, n, text)
	local lines = getTable(path)
	lines[n] = text
	fwriteFromTable(path, lines)
end

function getName(path)
	if exists(path) then
		local lastSlashPos = 1
		for i = 1, path:len() do
			if path:sub(i, i) == "/" then
				lastSlashPos = i
			end
		end
		
		return path:sub(lastSlashPos + 1)
	end
	return ""
end

function getPath(path)
	if exists(path) then
		local lastSlashPos = 1
		for i = 1, path:len() do
			if path:sub(i, i) == "/" then
				lastSlashPos = i
			end
		end
		
		return path:sub(1, lastSlashPos)
	end
	return ""
end

function fremove(path)
	os.remove(path)
end