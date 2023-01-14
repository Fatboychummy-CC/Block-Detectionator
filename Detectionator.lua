local QIT = require "QIT"
local file_helper = require "file_helper"
local menus = require "menus"

local DIR = fs.getDir(shell.getRunningProgram())
local CACHE_FILE = fs.combine(DIR, "cache.dat")
local HIGHLIGHTS_FILE = fs.combine(DIR, "highlights.dat")
local ORES_FILE = fs.combine(DIR, "ores.dat")
local UNKNOWNS_FILE = fs.combine(DIR, "unknowns.dat")
local SETTINGS_FILE = fs.combine(DIR, "settings.dat")
local block_cache = file_helper.unserialize(CACHE_FILE)

--- Get the block cache as a sorted list of just the block IDs.
---@return string[] cache_list Sorted list of blocks sorted by their cached name.
local function get_cache()
  local t = QIT()

  for id in pairs(block_cache) do t:Insert(id) end
  table.sort(t, function(a, b)
    return block_cache[a] < block_cache[b]
  end)

  return t:Clean()
end

local cache_ids_only = get_cache()

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

local highlights = file_helper.unserialize(HIGHLIGHTS_FILE, {})
local ores = file_helper.unserialize(ORES_FILE, {
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
local unknowns = file_helper.unserialize(UNKNOWNS_FILE, {})
local set = file_helper.unserialize(SETTINGS_FILE, {
  ["display.refresh_rate"] = 1,
  ["display.offset_by_gps"] = true
})

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
    file_helper.serialize(HIGHLIGHTS_FILE, highlights, true)
  else
    file_helper.serialize(ORES_FILE, ores, true)
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
    if selection ~= RETURN then
      local display_name = menus.question(main_window, "Add block from list",
        "What is the display name for the block '" .. selection .. "' (Example: Oak Sapling)? Leave blank to cancel.")

      if display_name ~= "" then
        unknowns[selection] = nil
        block_cache[selection] = display_name
        menu.removeSelection(selection)
        file_helper.serialize(CACHE_FILE, block_cache, true)
      end
    end
  until selection == RETURN
end

local function manual_add_menu()
  local block_id = menus.question(main_window, "Add block manually",
    "What is the block's block id (Example: minecraft:oak_sapling)?")
  local display_name = menus.question(main_window, "Add block manually",
    "What is the block's display name (Example: Oak Sapling)? Leave blank to cancel.")

  if display_name ~= "" then
    block_cache[block_id] = display_name
    file_helper.serialize(CACHE_FILE, block_cache, true)
  end
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
    cache_ids_only = get_cache()
  until selection == RETURN
end

--- Settings page to set settings settingly
local function settings_menu()
  local menu = menus.create(main_window, "Settings")
  local REFRESH_RATE = "refresh_rate"
  local USE_GPS = "use_gps"
  local RETURN = "return"

  local function refresh_rate_value()
    return tostring(set["display.refresh_rate"])
  end

  local function gps_value()
    return set["display.offset_by_gps"] and "Auto" or "Off"
  end

  local overrides = {
    override_width = 10
  }

  menu.addSelection(REFRESH_RATE, "Refresh Rate", refresh_rate_value,
    "Change the refresh rate: 0.25, 1, 2, 3, 4, 5, 10", overrides)
  menu.addSelection(USE_GPS, "Use GPS", gps_value, "Toggle usage of GPS to smooth block positioning: Off, Auto",
    overrides)
  menu.addSelection(RETURN, "Return", "Go back.", "Go to the previous menu.", overrides)

  local refresh_next = {
    unknown = 1,
    [0.25] = 1,
    2,
    3,
    4,
    5,
    10,
    [10] = 0.25
  }

  repeat
    local selection = menu.run()

    if selection == REFRESH_RATE then
      if refresh_next[set["display.refresh_rate"]] then
        set["display.refresh_rate"] = refresh_next[set["display.refresh_rate"]]
      else
        set["display.refresh_rate"] = refresh_next.unknown
      end
    elseif selection == USE_GPS then
      set["display.offset_by_gps"] = not set["display.offset_by_gps"]
    end
  until selection == RETURN

  file_helper.serialize(SETTINGS_FILE, set)
end

--- Main menu. Display a bunch of crap and whatnot.
local function main_menu()
  local menu = menus.create(main_window, "Block Detectionator")
  local TOGGLE = "toggle"
  local ORES = "ores"
  local HIGHLIGHTS = "highlights"
  local UNKNOWN = "unknown"
  local SETTINGS = "settings"
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
  menu.addSelection(SETTINGS, "Settings", "Change other settings.",
    "Press enter to change a bunch of other, random settings.")
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
    elseif selection == SETTINGS then
      settings_menu()
    end
  until selection == EXIT
end

--- Main scanning thread. Scan ores while displaying, otherwise hide everything.
local group = canvas.addGroup({ 0, 0 })
local function scan()
  group.addText({ 1, 1 }, "Blocks detected:")
  group.addText({ 1, 12 }, "Blocks highlighted:")
  group.addText({ 1, 23 }, "GPS Lock:")
  group.addRectangle(0, 0, 120, 32).setColor(0, 0, 0, 100)
  local DETECT_POS = { 85, 1 }
  local HIGHLIGHT_POS = { 94, 12 }
  local GPS_POS = { 50, 23 }

  local tracked = QIT()
  while true do
    -- in theory this should give us the finest positioning...
    local gx, gy, gz = 0, 0, 0
    local gps_lock = false
    local wanted
    parallel.waitForAll(
      function()
        wanted = detect()
      end,
      set["display.offset_by_gps"] and
      function()
        local x, y, z = gps.locate()
        if x then
          gx, gy, gz = x, y, z
          gps_lock = true
        end
      end or function() end
    )

    gx, gy, gz = gx % 1, gy % 1, gz % 1

    while tracked.n > 0 do
      tracked:Remove().remove()
    end

    if is_displaying then
      os.queueEvent "menu_redraw"

      -- display counts of ores and highlights
      tracked:Insert(group.addText(DETECT_POS, tostring(wanted.ores.n)))
      tracked:Insert(group.addText(HIGHLIGHT_POS, tostring(wanted.highlights.n)))
      local gps_text = group.addText(GPS_POS,
        gps_lock and "LOCKED" or set["display.offset_by_gps"] and "FAIL" or "DISABLED")
      if gps_lock then
        gps_text.setColor(0, 255, 0)
      else
        gps_text.setColor(255, 0, 0)
      end

      tracked:Insert(gps_text)

      -- clear what is drawn to the 3d canvases (canvi?)
      highlight_canvas.clear()
      highlight_canvas.recenter()
      ore_canvas.clear()
      ore_canvas.recenter()

      -- Add all the ores
      for i = 1, wanted.ores.n do
        local ore = wanted.ores[i]
        local scale = 1 ---@TODO close fade
        local item = ore_canvas.addItem({ ore.x - gx + 0.5, ore.y - gy + 0.5, ore.z - gz + 0.5 },
          ore.name, scale, scale, scale)
        item.setDepthTested(false)
      end

      -- Highlight ores
      for i = 1, wanted.highlights.n do
        local ore = wanted.highlights[i]
        local scale = 1 ---@TODO Close fade
        scale = scale + 0.3 * scale + 0.1
        local item = highlight_canvas.addBox(ore.x + 0.5 - gx - scale / 2, ore.y + 0.5 - gy - scale / 2,
          ore.z + 0.5 - gz - scale / 2, scale, scale, scale, 0xffffffff)
        item.setDepthTested(false)
      end
    else
      highlight_canvas.clear()
      ore_canvas.clear()
    end
    sleep(set["display.refresh_rate"])
  end
end

local ok, err = pcall(parallel.waitForAny, main_menu, scan)
group.clear()

if not ok then
  print()
  printError(err)
end
