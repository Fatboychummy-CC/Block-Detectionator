local block_data = require "data"
local file_helper = require "file_helper"

local modules = peripheral.wrap "back"

---@type function
---@diagnostic disable-next-line
local doScan = modules.scan and modules.scan or error("Missing block scanner!", 0)
---@type table
---@diagnostic disable-next-line shutup shutup shutup shutup shutup shutup shutup
local canvas3d = modules.canvas3d and modules.canvas3d() or error("Missing overlay glasses!", 0)
local canvas = modules.canvas() -- canvas exists if canvas3d exists
local highlightCanvas, oreCanvas = canvas3d.create(), canvas3d.create()

local isDisplaying = true
local locate = gps.locate
local w, h = term.getSize()
local consoleWindow = window.create(term.current(), 1, 10, w, h - 8)

local dir = fs.getDir(shell.getRunningProgram())

local highlights = file_helper.unserialize(fs.combine(dir, "highlights.lua", {}))

