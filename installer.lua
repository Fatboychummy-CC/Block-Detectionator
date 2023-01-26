--- Installer program to install Detectionator.

local args = table.pack(...)

local RUNNING = shell.getRunningProgram()
local DIR = shell.dir()
local NAME = fs.getName(RUNNING)
if NAME:match("wget%.lua") then
  NAME = "installer.lua"
end

local DIR_TO = fs.combine(DIR, args[2] or "")

---@type table<string, string>
local files_needed = {
  ["Detectionator.lua"] = "https://raw.githubusercontent.com/Fatboychummy-CC/Block-Detectionator/1.19/Detectionator.lua",
  ["QIT.lua"] = "https://raw.githubusercontent.com/Fatboychummy-CC/Block-Detectionator/1.19/QIT.lua",
  ["deep_copy.lua"] = "https://raw.githubusercontent.com/Fatboychummy-CC/Block-Detectionator/1.19/deep_copy.lua",
  ["file_helper.lua"] = "https://raw.githubusercontent.com/Fatboychummy-CC/Block-Detectionator/1.19/file_helper.lua",
  ["menus.lua"] = "https://raw.githubusercontent.com/Fatboychummy-CC/Block-Detectionator/1.19/menus.lua",

  ["cache.dat"] = "https://raw.githubusercontent.com/Fatboychummy-CC/Block-Detectionator/1.19/cache.dat",
  ["color_cache.dat"] = "https://raw.githubusercontent.com/Fatboychummy-CC/Block-Detectionator/1.19/color_cache.dat",
}


if not fs.exists(DIR_TO) then
  fs.makeDir(DIR_TO)
end

if fs.exists(DIR_TO) and not fs.isDir(DIR_TO) then
  error("That's a file, bruv.", 0)
end

print()
local w = term.getSize()
local _, y = term.getCursorPos()
local function progress(n, filename)
  local fill = math.floor(n * (w - 2))
  term.setCursorPos(1, y - 1)
  term.clearLine()
  term.write(filename)
  term.setCursorPos(1, y)

  term.write('[')
  term.write(('\x7F'):rep(fill))
  term.write(('\xB7'):rep(w - 2 - fill))
  term.write(']')
end

local count = 0
for _ in pairs(files_needed) do count = count + 1 end

local i = 0
for filename, remote in pairs(files_needed) do
  local output_file = fs.combine(DIR_TO, filename)

  progress(i / count, filename)
  i = i + 1

  local handle, err = http.get(remote)
  if not handle then
    print()
    error(err, 0)
  end

  local data = handle.readAll()
  handle.close()

  io.open(output_file, 'w'):write(data):close()
end

progress(1, "Done.")
