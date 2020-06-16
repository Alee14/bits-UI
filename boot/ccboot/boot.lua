if os.ccboot then
	term.setTextColor(colors.red);
	print("Insufficient memory.");
	error();
end;

-- Add ccboot identifier to OS variable
os.ccboot = true;
os.ccboot_version = "1.0";

-- Define constants
local VERSION = "1.0";
local AUTHOR_INFO = "Written by Adrian Ulbrich"
local INFO_TEXT = { "Use the up and down arrow keys to select", "which entry is highlighted.", "Press enter to boot the selected OS." };
local TIMEOUT_TEXT = { "The highlighted entry will be executed", "automatically in {TIMEOUT} seconds." };
local CONFIG_PATH = "boot/ccboot/ccboot.cfg";
local DEFAULT_SELECTED = 1;
local DEFAULT_TIMEOUT = -1;

-- Define local variables
local selected = nil;
local timeout = nil;
local entryNames = {};
local entryPaths = {};
local configFile;
local timeoutTimer = nil;

-- Always pull raw events
local pullEvent = os.pullEvent;
os.pullEvent = os.pullEventRaw;

-- Get terminal dimensions
local w, h = term.getSize();

-- Define functions
function string.startsWith(str, text)
    return string.sub(str, 1, string.len(text)) == text;
end;

function fatalError(text)
	term.setTextColor(colors.red);
	print(text);
	term.setTextColor(colors.white);
	print("press any key to reboot.");
	os.pullEvent("key");
	os.reboot();
end;

function printTimeoutText()
	for i, v in pairs(TIMEOUT_TEXT) do
		term.setCursorPos(6, h - 3 + i);
		write(string.gsub(v, "{TIMEOUT}", timeout));
	end;
end;

function removeTimeoutText()
	term.setTextColor(colors.black);
	printTimeoutText();
	term.setTextColor(colors.white);
end

function bootOS(index)
	local n = 1;
	for i, v in pairs(entryPaths) do
		if n == index then
			term.clear();
			term.setCursorPos(1, 1);
			os.pullEvent = pullEvent;
			shell.run(v);
			os.shutdown();
		end
		n = n + 1;
	end;
end;

-- Clear the screen
term.clear();
term.setCursorPos(1, 1);

-- Check if the config file exists
if not fs.exists(CONFIG_PATH) then
	fatalError("fatal error: ccboot config file could not be found (\"" .. CONFIG_PATH .. "\").");
end;

-- Read the config file
configFile = io.open(CONFIG_PATH, "r");
if configFile == nil then
	fatalError("fatal error: ccboot config file could not be opened for reading (\"" .. CONFIG_PATH .. "\").");
end;

for line in configFile:lines() do
	if string.startsWith(line, "selected ") then
		selected = tonumber(string.sub(line, #"selected " + 1));
	elseif string.startsWith(line, "timeout ") then
		timeout = tonumber(string.sub(line, #"timeout " + 1));
	elseif string.startsWith(line, "entry ") then
		local entry = string.sub(line, #"entry " + 1);
		local splitPos = string.find(entry, ";");
		local name = string.sub(entry, 1, splitPos - 1);
		local path = string.sub(entry, splitPos + 1);
		table.insert(entryNames, name);
		table.insert(entryPaths, path);
	end;
end;

if selected == nil then selected = DEFAULT_SELECTED end;
if timeout == nil then timeout = DEFAULT_TIMEOUT end;

io.close(configFile);

local nameString = "CCboot  version " .. VERSION;

-- Print the name at the top
term.setCursorPos((w - #nameString) / 2, 2);
write(nameString);
term.setCursorPos((w - #AUTHOR_INFO) / 2, 3);
write(AUTHOR_INFO);

for i, v in pairs(INFO_TEXT) do
	term.setCursorPos(6, h - 6 + i);
	write(v);
end;

if timeout > -1 then
	timeoutTimer = os.startTimer(1);
	printTimeoutText();
end;

-- Print the entries and handle keyboard input
while true do
	local printIndex = 1;
	for i, v in pairs(entryNames) do
		if printIndex == selected then
			term.setTextColor(colors.black);
			term.setBackgroundColor(colors.white);
		end;
		term.setCursorPos(3, 5 + printIndex - 1);
		for i=0,w - 6 do write(' ') end
		term.setCursorPos(3, 5 + printIndex - 1);
		print(v);
		if printIndex == selected then
			term.setTextColor(colors.white);
			term.setBackgroundColor(colors.black);
		end;
		printIndex = printIndex + 1;
	end
	
	local event, val = os.pullEvent();
	if event == "key" then
		if val == keys.up then
			selected = selected - 1;
			os.cancelTimer(timeoutTimer);
			removeTimeoutText();
		elseif val == keys.down then
			selected = selected + 1;
			os.cancelTimer(timeoutTimer);
			removeTimeoutText();
		elseif val == keys.enter then
			bootOS(selected);
		end;
		
		if selected < 1 then
			selected = 1;
		elseif selected >= printIndex then
			selected = selected - 1;
		end;		
		
	elseif event == "timer" and val == timeoutTimer then
		timeout = timeout - 1;
		printTimeoutText();
		
		if timeout == -1 then
			bootOS(selected);
		end;
		timeoutTimer = os.startTimer(1);
	end;
end;
