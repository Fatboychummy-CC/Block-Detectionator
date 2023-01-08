local block_cache = require "cache"
local QIT = require "QIT"
local cache_ids_only = (
    function() local t = QIT()
      for id in pairs(block_cache) do t:Insert(id) end
      table.sort(t, function(a, b)
        return block_cache[a] < block_cache[b]
      end)
      return t:Clean()
    end
    )()
local file_helper = require "file_helper"
local menus = require "menus"

local modules = peripheral.wrap "back"

---@type function
---@diagnostic disable-next-line
local scan = modules.scan and modules.scan or error("Missing block scanner!", 0)
---@type table
---@diagnostic disable-next-line shutup shutup shutup shutup shutup shutup shutup
local canvas3d = modules.canvas3d and modules.canvas3d() or error("Missing overlay glasses!", 0)
local canvas = modules.canvas() -- canvas exists if canvas3d exists
local highlight_canvas, ore_canvas = canvas3d.create(), canvas3d.create()

local is_displaying = true
local locate = gps.locate
local w, h = term.getSize()
local main_window = window.create(term.current(), 1, 1, w, h)

local dir = fs.getDir(shell.getRunningProgram())

local highlights = file_helper.unserialize(fs.combine(dir, "highlights.lua"), {})
local ores = file_helper.unserialize(fs.combine(dir, "ores.lua"), {
  ["minecraft:coal_ore"] = true,
  ["minecraft:iron_ore"] = true,
  ["minecraft:gold_ore"] = true,
  ["minecraft:copper_ore"] = true,
  ["minecraft:diamond_ore"] = true,
  ["minecraft:lapis_ore"] = true,
  ["minecraft:emerald_ore"] = true,
  ["minecraft:redstone_ore"] = true,
  ["minecraft:deepslate_coal_ore"] = true,
  ["minecraft:deepslate_iron_ore"] = true,
  ["minecraft:deepslate_gold_ore"] = true,
  ["minecraft:deepslate_copper_ore"] = true,
  ["minecraft:deepslate_diamond_ore"] = true,
  ["minecraft:deepslate_lapis_ore"] = true,
  ["minecraft:deepslate_emerald_ore"] = true,
  ["minecraft:deepslate_redstone_ore"] = true,
  ["minecraft:nether_quartz_ore"] = true,
  ["minecraft:nether_gold_ore"] = true,
  ["minecraft:ancient_debris"] = true,
})
local unknowns = file_helper.unserialize(fs.combine(dir, "unknowns.lua"), {})

local function get_as_list(t)
  local list = QIT()

  for value in pairs(t) do
    list:Insert(value)
  end

  table.sort(list)

  return list:Clean()
end

--- Scan, then return information about blocks that we are searching for.
---@return {ores:block_data[], highlights:block_data[]} scan_data
local function detect()
  local blocks = scan()
  local wanted = { ores = QIT(), highlights = QIT() }

  for _, block_info in ipairs(blocks) do
    if ores[block_info.name] then
      wanted.ores:Insert(block_info)
    end
    if highlights[block_info.name] then
      wanted.highlights:Insert(block_info)
    end
    if not block_cache[block_info.name] then
      unknowns[block_info.name] = true
    end
  end

  wanted.ores:Clean()
  wanted.highlights:Clean()

  return wanted
end

--- Count the number of items in a dictionary style table.
---@param t table The table to count.
---@return integer count The amount of items in the table.
local function count_kv(t)
  local n = 0

  for _ in pairs(t) do n = n + 1 end

  return n
end

--- Given a table of blocks, toggle them
---@param blocks string[] The blocks to add via their block IDs
---@param toggle_type toggle_type
local function blocks_toggle_menu(blocks, toggle_type)
  local menu = menus.create(main_window, "Toggle blocks")

  local RETURN = "return"

  ---@param block_id string
  ---@return string
  local function is_enabled(block_id)
    if toggle_type == "highlights" then
      if highlights[block_id] then
        return "Enabled."
      else
        return "Disabled."
      end
    else
      if ores[block_id] then
        return "Enabled."
      else
        return "Disabled."
      end
    end
  end

  local overrides = {
    override_width = 8
  }

  menu.addSelection(RETURN, "Return", "Go back.", "Return to the previous menu, saving any changes.", overrides)

  for _, id in ipairs(blocks) do
    menu.addSelection(id, block_cache[id] or "unknown", is_enabled,
      "Toggle the block '" .. (block_cache[id] or ("Unknown<%s>"):format(id)) .. "'.", overrides)
  end

  repeat
    local selection = menu.run()

    if selection ~= RETURN then
      if toggle_type == "highlights" then
        highlights[selection] = not highlights[selection]
        if not highlights[selection] then
          highlights[selection] = nil
        end
      else
        ores[selection] = not ores[selection]
        if not ores[selection] then
          ores[selection] = nil
        end
      end
    end
  until selection == RETURN

  if toggle_type == "highlights" then
    file_helper.serialize(fs.combine(dir, "highlights.lua"), highlights, true)
  else
    file_helper.serialize(fs.combine(dir, "ores.lua"), ores, true)
  end
end

--- Search for blocks given a search string. Empty string will return all.
---@param search string The value to search for.
---@return string[] blocks The block ids found.
local function search_blocks(search)
  if search == "" then
    return cache_ids_only
  end

  local found = QIT()

  for id, name in pairs(block_cache) do
    if name:lower():find(search) then
      found:Insert(id)
    end
  end

  table.sort(found, function(a, b)
    return block_cache[a] < block_cache[b]
  end)

  return found:Clean()
end

--- Choose to search by name or by currently enabled.
---@param toggle_type toggle_type
local function blocks_menu(toggle_type)
  local menu = menus.create(main_window, "Block panel")
  local SEARCH = "search"
  local ENABLED = "enabled"
  local RETURN = "return"

  local function search_value()
    return string.format("Search %d blocks.", count_kv(block_cache))
  end

  local function enabled_value()
    return string.format("View %d enabled blocks.", count_kv(toggle_type == "highlights" and highlights or ores))
  end

  menu.addSelection(SEARCH, "Search", search_value, "Search for blocks via their name.")
  menu.addSelection(ENABLED, "Enabled", enabled_value, "Search for blocks which are currently enabled.")
  menu.addSelection(RETURN, "Return", "Go back.", "Go to the previous menu.")

  repeat
    local selection = menu.run()

    if selection == SEARCH then
      local search = menus.question(main_window, "Search for blocks", "Enter a search string below to search for blocks.")
      blocks_toggle_menu(search_blocks(search:lower()), toggle_type)
    elseif selection == ENABLED then
      if toggle_type == "highlights" then

        blocks_toggle_menu(get_as_list(highlights), toggle_type)
      else
        blocks_toggle_menu(get_as_list(ores), toggle_type)
      end
    end
  until selection == RETURN
end

local function list_add_menu()
  local menu = menus.create(main_window, "Add block from list")
  local RETURN = "return"

  local overrides = {
    override_width = 0
  }

  menu.addSelection(RETURN, "Return", "Go back.", "Go to the previous menu.")
  for id in pairs(unknowns) do
    menu.addSelection(id, id, "", ("Add information for '%s'"):format(id), overrides)
  end

  repeat
    local selection = menu.run()
  until selection == RETURN
end

local function manual_add_menu()
  local block_id = menus.question(main_window, "Add block manually",
    "What is the block's block id (Example: minecraft:oak_sapling)?")
  local display_name = menus.question(main_window, "Add block manually",
    "What is the block's display name (Example: Oak Sapling)?")

  block_cache[block_id] = display_name
  file_helper.serializeReturn(fs.combine(dir, "cache.lua"), block_cache, true)
end

--- Display unknown blocks and ask for names for them. Adds to cache.
local function unknown_menu()
  local menu = menus.create(main_window, "Add block information")
  local MANUAL = "manual"
  local LIST = "list"
  local RETURN = "return"

  local function list_value()
    return string.format("Scanned %d unknown blocks.", count_kv(unknowns))
  end

  menu.addSelection(MANUAL, "Manual", "Add blocks manually.", "Add blocks by providing the block ID and display name.")
  menu.addSelection(LIST, "List", list_value, "From the list of scanned blocks, provide a display name.")
  menu.addSelection(RETURN, "Return", "Go back.", "Go to the previous menu.")

  repeat
    local selection = menu.run()

    if selection == MANUAL then
      manual_add_menu()
    elseif selection == LIST then
      list_add_menu()
    end
  until selection == RETURN
end

--- Main menu. Display a bunch of crap and whatnot.
local function main_menu()
  local menu = menus.create(main_window, "Block Detectionator")
  local TOGGLE = "toggle"
  local ORES = "ores"
  local HIGHLIGHTS = "highlights"
  local UNKNOWN = "unknown"
  local EXIT = "exit"

  local function toggle_value()
    return is_displaying and "Running" or "Not running"
  end

  local function ores_value()
    return string.format("Scanning for %d blocks.", count_kv(ores))
  end

  local function highlights_value()
    return string.format("Highlighting %d blocks.", count_kv(highlights))
  end

  local function unknown_value()
    return string.format("Scanned %d unknown blocks.", count_kv(unknowns))
  end

  menu.addSelection(TOGGLE, "Toggle", toggle_value, "Press enter to toggle this on or off.")
  menu.addSelection(ORES, "Blocks", ores_value, "Press enter to edit the blocks being scanned for.")
  menu.addSelection(HIGHLIGHTS, "Highlights", highlights_value, "Press enter to edit the highlights.")
  menu.addSelection(UNKNOWN, "Unknown", unknown_value, "Press enter to add unknown blocks to the cache.")
  menu.addSelection(EXIT, "Exit", "Exit this program.", "Return to the CraftOS shell.")

  repeat
    local selection = menu.run()
    if selection == TOGGLE then
      is_displaying = not is_displaying
    elseif selection == ORES then
      blocks_menu("blocks")
    elseif selection == HIGHLIGHTS then
      blocks_menu("highlights")
    elseif selection == UNKNOWN then
      unknown_menu()
    end
  until selection == EXIT
end

--- Main scanning thread. Scan ores while displaying, otherwise hide everything.
local function scan()
  while true do
    detect()
    os.queueEvent "menu_redraw"
    sleep(5)
  end
end

parallel.waitForAny(main_menu, scan)
