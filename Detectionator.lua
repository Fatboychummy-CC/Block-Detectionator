local modules = peripheral.wrap "back"

local ok, writer = pcall(require, "ccanvas")

local doScan = modules.scan and modules.scan or error("Missing block scanner!", 0)
---@type table
---@diagnostic disable-next-line shutup shutup shutup shutup shutup shutup shutup
local canvas3d = modules.canvas3d and modules.canvas3d() or error("Missing overlay glasses!", 0)
local canvas = modules.canvas()
canvas3d.clear()
local highlightCanvas, oreCanvas = canvas3d.create(), canvas3d.create()
local bIsDisplaying = true
local mX, mY = term.getSize()
local consoleWindow = window.create(term.current(), 1, 10, mX, mY - 8)
local locate = gps.locate
local highlightsFile = ".highlights"

if not ok then
  local colorConvert = {
    [colors.white]     = { 240, 240, 240 },
    [colors.orange]    = { 242, 178, 51 },
    [colors.magenta]   = { 229, 127, 216 },
    [colors.lightBlue] = { 153, 178, 242 },
    [colors.yellow]    = { 222, 222, 108 },
    [colors.lime]      = { 127, 204, 25 },
    [colors.pink]      = { 242, 178, 204 },
    [colors.gray]      = { 76, 76, 76 },
    [colors.lightGray] = { 153, 153, 153 },
    [colors.cyan]      = { 76, 153, 178 },
    [colors.purple]    = { 178, 102, 229 },
    [colors.blue]      = { 51, 102, 204 },
    [colors.brown]     = { 127, 102, 76 },
    [colors.green]     = { 87, 166, 78 },
    [colors.red]       = { 204, 76, 76 },
    [colors.black]     = { 17, 17, 17 }
  }

  --- Write to the player's screen
  ---@param text string The text to write.
  ---@param x integer The x position.
  ---@param y integer The y position.
  ---@param color colour The color to be used.
  writer = function(text, x, y, color)
    local converted = colorConvert[color] or error("Invalid color.", 2)
    local tmp = canvas.addText({ x, y }, text)

    tmp.setColor(converted[1], converted[2], converted[3])
  end
end

local tOreDict = {
  ["actuallyadditions:block_misc"] = { 3 },
  ["minecraft:iron_ore"] = { 0 },
  ["minecraft:gold_ore"] = { 0 },
  ["minecraft:diamond_ore"] = { 0 },
  ["minecraft:coal_ore"] = { 0 },
  ["minecraft:lapis_ore"] = { 0 },
  ["minecraft:emerald_ore"] = { 0 },
  ["minecraft:quartz_ore"] = { 0 },
  ["minecraft:redstone_ore"] = { 0 },
  ["thermalfoundation:ore"] = { 0, 1, 2, 3, 4, 5, 6, 7, 8 },
  ["thermalfoundation:ore_fluid"] = { 0, 1, 2, 3, 4, 5 },
  ["railcraft:ore_metal"] = { 0, 1, 2, 3, 4, 5 },
  ["railcraft:ore_metal_poor"] = { 0, 1, 2, 3, 4, 5, 6, 7 },
  ["bno:ore_netherdiamond"] = { 0 },
  ["bno:ore_netheremerald"] = { 0 },
  ["bno:ore_netherredstone"] = { 0 },
  ["bno:ore_netheriron"] = { 0 },
  ["bno:ore_nethergold"] = { 0 },
  ["bno:ore_nethercoal"] = { 0 },
  ["bno:ore_nethertin"] = { 0 },
  ["bno:ore_nethercopper"] = { 0 },
  ["bno:ore_netherlapis"] = { 0 },
  ["dungeontactics:nethergold_ore"] = { 0 },
  ["ic2:blockmetal"] = { 0, 1, 2, 3 },
  ["appliedenergistics2:quartz_ore"] = { 0 },
  ["appliedenergistics2:charged_quartz_ore"] = { 0 },
  ["dungeontactics:silver_ore"] = { 0 },
  ["dungeontactics:mithril_ore"] = { 0 },
  ["dungeontactics:stonequartz_ore"] = { 0 },
  ["dungeontactics:enddiamond_ore"] = { 0 },
  ["dungeontactics:endlapis_ore"] = { 0 },
  ["galacticraftcore:basic_block_core"] = { 5, 6, 7, 8 },
  ["galacticraftcore:basic_block_moon"] = { 0, 1, 2, 6 },
  ["galacticraftplanets:mars"] = { 0, 1, 2, 3 },
  ["galacticraftplanets:asteroids_block"] = { 3, 5 },
  ["galacticraftplanets:venus"] = { 6, 7, 8, 9, 10, 11, 13 },
  ["rftools:dimensional_shard_ore"] = { 0, 1, 2 },
  ["quark:biotite_ore"] = { 0 },
  ["railcraft:ore"] = { 0, 1, 2, 3, 4 },
  ["railcraft:ore_magic"] = { 0 },
  ["tconstruct:ore"] = { 0, 1 },
  ["mekanism:oreblock"] = { 0, 1, 2 },
}
local tOreNames = {
  ["actuallyadditions:block_misc:::3"] = "Black Quartz",
  ["minecraft:iron_ore:::0"] = "Iron",
  ["minecraft:gold_ore:::0"] = "Gold",
  ["minecraft:diamond_ore:::0"] = "Diamond",
  ["minecraft:coal_ore:::0"] = "Coal",
  ["minecraft:lapis_ore:::0"] = "Lapis Lazuli",
  ["minecraft:emerald_ore:::0"] = "Emerald",
  ["minecraft:quartz_ore:::0"] = "Nether Quartz",
  ["minecraft:redstone_ore:::0"] = "Redstone",
  ["thermalfoundation:ore:::0"] = "Copper",
  ["thermalfoundation:ore:::1"] = "Tin",
  ["thermalfoundation:ore:::2"] = "Silver",
  ["thermalfoundation:ore:::3"] = "Lead",
  ["thermalfoundation:ore:::4"] = "Aluminum",
  ["thermalfoundation:ore:::5"] = "Nickel",
  ["thermalfoundation:ore:::6"] = "Platinum",
  ["thermalfoundation:ore:::7"] = "Iridium",
  ["thermalfoundation:ore:::8"] = "Mana Infused",
  ["thermalfoundation:ore_fluid:::0"] = "Oil Sand (yellow)",
  ["thermalfoundation:ore_fluid:::1"] = "Oil Shale",
  ["thermalfoundation:ore_fluid:::2"] = "Destabilized Redstone",
  ["thermalfoundation:ore_fluid:::3"] = "Energized Netherrack",
  ["thermalfoundation:ore_fluid:::4"] = "Resonant End Stone",
  ["thermalfoundation:ore_fluid:::5"] = "Oil Sand (orange)",
  ["railcraft:ore_metal:::0"] = "Copper",
  ["railcraft:ore_metal:::1"] = "Tin",
  ["railcraft:ore_metal:::2"] = "Lead",
  ["railcraft:ore_metal:::3"] = "Silver",
  ["railcraft:ore_metal:::4"] = "Nickel",
  ["railcraft:ore_metal:::5"] = "Zinc",
  ["railcraft:ore_metal_poor:::0"] = "Poor Iron",
  ["railcraft:ore_metal_poor:::1"] = "Poor Gold",
  ["railcraft:ore_metal_poor:::2"] = "Poor Copper",
  ["railcraft:ore_metal_poor:::3"] = "Poor Tin",
  ["railcraft:ore_metal_poor:::4"] = "Poor Lead",
  ["railcraft:ore_metal_poor:::5"] = "Poor Silver",
  ["railcraft:ore_metal_poor:::6"] = "Poor Nickel",
  ["railcraft:ore_metal_poor:::7"] = "Poor Zinc",
  ["bno:ore_netherdiamond:::0"] = "Nether Diamond",
  ["bno:ore_netheremerald:::0"] = "Nether Emerald",
  ["bno:ore_netherredstone:::0"] = "Nether Redstone",
  ["bno:ore_netheriron:::0"] = "Nether Iron",
  ["bno:ore_nethergold:::0"] = "Nether Gold",
  ["bno:ore_nethercoal:::0"] = "Nether Coal",
  ["bno:ore_nethertin:::0"] = "Nether Tin",
  ["bno:ore_nethercopper:::0"] = "Nether Copper",
  ["bno:ore_netherlapis:::0"] = "Nether Lapis",
  ["dungeontactics:nethergold_ore:::0"] = "Nether Gold",
  ["ic2:blockmetal:::0"] = "Copper",
  ["ic2:blockmetal:::1"] = "Tin",
  ["ic2:blockmetal:::2"] = "Uranium",
  ["ic2:blockmetal:::3"] = "Silver",
  ["appliedenergistics2:quartz_ore:::0"] = "Certus Quartz",
  ["appliedenergistics2:charged_quartz_ore:::0"] = "Charged Certus Quartz",
  ["dungeontactics:silver_ore:::0"] = "Silver",
  ["dungeontactics:mithril_ore:::0"] = "Mithril",
  ["dungeontactics:stonequartz_ore:::0"] = "Nether Quartz (overworld)",
  ["dungeontactics:enddiamond_ore:::0"] = "End Diamond",
  ["dungeontactics:endlapis_ore:::0"] = "End Lapis Lazuli",
  ["galacticraftcore:basic_block_core:::5"] = "Copper",
  ["galacticraftcore:basic_block_core:::6"] = "Tin",
  ["galacticraftcore:basic_block_core:::7"] = "Aluminum",
  ["galacticraftcore:basic_block_core:::8"] = "Silicon",
  ["galacticraftcore:basic_block_moon:::0"] = "Moon Copper",
  ["galacticraftcore:basic_block_moon:::1"] = "Moon Tin",
  ["galacticraftcore:basic_block_moon:::2"] = "Moon Cheese",
  ["galacticraftcore:basic_block_moon:::6"] = "Moon Sapphire",
  ["galacticraftplanets:mars:::0"] = "Mars Copper",
  ["galacticraftplanets:mars:::1"] = "Mars Tin",
  ["galacticraftplanets:mars:::2"] = "Mars Desh",
  ["galacticraftplanets:mars:::3"] = "Mars Iron",
  ["galacticraftplanets:asteroids_block:::3"] = "Asteroids Aluminum",
  ["galacticraftplanets:asteroids_block:::5"] = "Asteroids Iron",
  ["galacticraftplanets:venus:::6"] = "Venus Aluminum",
  ["galacticraftplanets:venus:::7"] = "Venus Copper",
  ["galacticraftplanets:venus:::8"] = "Venus Galena",
  ["galacticraftplanets:venus:::9"] = "Venus Quartz",
  ["galacticraftplanets:venus:::10"] = "Venus Silicon",
  ["galacticraftplanets:venus:::11"] = "Venus Tin",
  ["galacticraftplanets:venus:::13"] = "Venus Solar",
  ["rftools:dimensional_shard_ore:::0"] = "Dimensional Shard (overworld)",
  ["rftools:dimensional_shard_ore:::1"] = "Dimensional Shard (nether)",
  ["rftools:dimensional_shard_ore:::2"] = "Dimensional Shard (end)",
  ["quark:biotite_ore:::0"] = "Biotite",
  ["railcraft:ore:::0"] = "Sulfur",
  ["railcraft:ore:::1"] = "Saltpeter",
  ["railcraft:ore:::2"] = "Dark Diamond",
  ["railcraft:ore:::3"] = "Dark Emerald",
  ["railcraft:ore:::4"] = "Dark Lapis Lazuli",
  ["railcraft:ore_magic:::0"] = "Firestone",
  ["tconstruct:ore:::0"] = "Cobalt",
  ["tconstruct:ore:::1"] = "Ardite",
  ["mekanism:oreblock:::0"] = "Osmium",
  ["mekanism:oreblock:::1"] = "Copper",
  ["mekanism:oreblock:::2"] = "Tin",
}

do
  local names = {}

  -- Determine the copies
  for id, name in pairs(tOreNames) do
    if names[name] then
      -- insert this id into the table of names for current name.
      table.insert(names[name], id)
    else
      -- initialize a table for the current name:id.
      names[name] = { id }
    end
  end

  -- For each copy, append "(modname)" to the end
  for name, ids in pairs(names) do
    -- if there is more than one id, then we have a copy.
    if #ids > 1 then
      for _, id in ipairs(ids) do
        -- Copper (mekanism)
        tOreNames[id] = string.format("%s (%s)", name, id:match("(.-)%:"))
      end
    end
  end
end

local function saveFile(sData, sFileName)
  local h, err = io.open(sFileName, 'w')
  if not h then
    error(err, 0)
  end

  h:write(sData):close()
end

local function loadFile(sFileName)
  local h, err = io.open(sFileName, 'r')
  if not h then
    saveFile("{}", sFileName)
    h, err = io.open(sFileName, 'r')
    if not h then
      error(err, 0)
    end
  end

  local sData = h:read("*a")
  h:close()

  return textutils.unserialize(sData)
end

local tOresHighlighted = loadFile(highlightsFile)

--[[
  Deep copy a table.
  @param t The table to be copied
  @return A table of copied values, or t if t is not a table.
]]
local copyCount = 0
local function dCopy(t)
  copyCount = copyCount + 1
  -- if we have ourselves a table, clone it recursively
  if type(t) == "table" then
    local r = {}
    for k, v in pairs(t) do
      if type(v) == "table" then
        -- recurse, if value is a table.
        r[k] = dCopy(v)
      else
        -- otherwise just copy it
        r[k] = v
      end
    end

    -- then return our finished table.
    return r
  end

  -- if it is not a table, just return the item.
  return t
end

--[[
  Ping for a table of things
  @param detect The blocks to be scanned for.
  @param scan Either a table of prescanned items, or a function which returns a table of objects.
  @return the blocks detected.
]]
local function pingFor(tDetect, scan)
  if type(scan) == "function" then
    scan = scan()
  end

  local found = { n = 0 }

  -- loop through each item scanned
  for i = 1, #scan do
    local tCurrentBlockScan = scan[i]

    -- and all items we want to detect
    for sName, tDamages in pairs(tDetect) do
      local foundFlag = false

      -- check if this is the block we want
      if sName == tCurrentBlockScan.name then
        for j = 1, #tDamages do
          if tDamages[j] == tCurrentBlockScan.metadata then
            foundFlag = true
            found.n = found.n + 1
            found[found.n] = dCopy(tCurrentBlockScan)
            break
          end
        end
      end

      -- if we indeed found it, stop searching as we've already found it.
      if foundFlag then
        break
      end
    end
  end

  return found
end

local function isDisplaying()
  return tostring(bIsDisplaying)
end

local function numOres()
  local n = 0
  for k, v in pairs(tOreDict) do
    n = n + 1
  end
  return string.format("Searching for %d blocks.", n)
end

local function MenuOptions(options, stopsOnSelection)
  local selection = 1

  local function redraw()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()

    for i = 1, #options do
      term.setTextColor(colors.white)
      term.setCursorPos(2, i)
      term.write(options[i][1])

      term.setTextColor(colors.lightGray)
      term.setCursorPos(14, i)
      term.write(options[i][2]())
    end
    term.setTextColor(colors.yellow)
    for i = 1, #options do
      term.setCursorPos(1, i)
      if i == selection then
        term.write ">"
      else
        term.write " "
      end
    end
  end

  while true do
    redraw()
    local _, key = os.pullEvent "key"

    if key == keys.enter then
      if selection == stopsOnSelection then
        return
      end
      term.clear()
      options[selection][3]()
    elseif key == keys.backspace then
      return
    elseif key == keys.up then
      selection = selection - 1
      if selection < 1 then
        selection = #options
      end
    elseif key == keys.down then
      selection = selection + 1
      if selection > #options then
        selection = 1
      end
    end
  end
end

local function toggleCB()
  bIsDisplaying = not bIsDisplaying
end

local function oresCB()

end

local function RadialSelector(options)
  local mx, my = term.getSize()
  local center = math.floor(my / 2 + 0.5)
  local current = 1

  if #options == 0 then
    term.clear()
    term.setCursorPos(1, 1)
    print("Nothing matches that.")
    os.sleep(2)
    return
  end

  local function redraw()
    term.setTextColor(colors.white)
    term.clear()
    local i, s = 0, 3
    for j = current, current + my / 2 do
      term.setCursorPos(s, center + i)
      if options[(j - 1) % #options + 1][2] then
        term.setTextColor(colors.green)
      else
        term.setTextColor(colors.red)
      end
      term.write(options[(j - 1) % #options + 1][1])

      i = i + 1
      if i % 2 == 0 then
        s = s - 1
      end
    end

    i, s = 1, 3
    for j = 0, my / 2 do
      term.setCursorPos(s, center - i)
      if options[(current - j - 2) % #options + 1][2] then
        term.setTextColor(colors.green)
      else
        term.setTextColor(colors.red)
      end
      term.write(options[(current - j - 2) % #options + 1][1])
      i = i + 1
      if i % 2 == 0 then
        s = s - 1
      end
    end

    term.setCursorPos(2, center)
    term.setTextColor(colors.yellow)
    term.write(">")

    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.yellow)
    term.setCursorPos(1, 1)
    term.write((" "):rep(mx))
    term.setCursorPos(1, 1)
    term.write("Press backspace to confirm/exit.")

    term.setCursorPos(1, 2)
    term.write((" "):rep(mx))
    term.setCursorPos(1, my - 1)
    term.write((" "):rep(mx))

    term.setCursorPos(1, my)
    term.write((" "):rep(mx))
    term.setCursorPos(1, my)
    term.write("Press enter to toggle block.")

    term.setBackgroundColor(colors.black)
  end

  while true do
    redraw()
    local _, key = os.pullEvent("key")
    if key == keys.enter then
      options[current][2] = not options[current][2]
    elseif key == keys.backspace then
      return
    elseif key == keys.down then
      current = current + 1
      if current > #options then
        current = 1
      end
    elseif key == keys.up then
      current = current - 1
      if current < 1 then
        current = #options
      end
    end
  end
end

local function insertIntoNoRepeat(t, n)
  for i = 1, #t do
    if t[i] == n then
      return
    end
  end
  t[#t + 1] = n
end

local function SearchHighlights()
  term.clear()
  term.setCursorPos(1, 1)
  term.write("Enter partial ore name: ")
  local name = read()

  local selected = {}
  for sModID, sName in pairs(tOreNames) do
    if sName:lower():find(name:lower()) then
      selected[sModID] = sName
    end
  end

  local options = {}
  for k, v in pairs(selected) do
    local damage = tonumber(k:match(":::(.+)"))
    local modid = k:match("(.+):::")
    local isIn = false

    if tOresHighlighted[modid] then
      for i, _damage in ipairs(tOresHighlighted[modid]) do
        if damage == _damage then
          isIn = true
          break
        end
      end
    end

    options[#options + 1] = { v, isIn, k }
  end

  RadialSelector(options)

  for i = 1, #options do
    local damage = tonumber(options[i][3]:match(":::(.+)"))
    local modid = options[i][3]:match("(.+):::")

    if not tOresHighlighted[modid] then
      tOresHighlighted[modid] = {}
    end

    if options[i][2] then
      insertIntoNoRepeat(tOresHighlighted[modid], damage)
    else
      for j = 1, #tOresHighlighted[modid] do
        if tOresHighlighted[modid][j] == damage then
          table.remove(tOresHighlighted[modid], j)
          break
        end
      end
    end
  end
end

local function Highlighted()

end

local function CountHighlights()
  local count = 0
  for _, tDamages in pairs(tOresHighlighted) do
    count = count + #tDamages
  end

  return string.format("%d highlights.", count)
end

local function highlightsCB()
  MenuOptions({
    { "Search", CountHighlights, SearchHighlights },
    { "Highlighted", CountHighlights, Highlighted },
    { "Go back", function() return "" end }
  }, 3)
end

local function menu()
  MenuOptions({
    { "Toggle", isDisplaying, toggleCB },
    { "Ores", numOres, oresCB },
    { "Highlights", CountHighlights, highlightsCB },
    { "Exit", function() return "" end }
  }, 4)
end

local fadeDistanceMax = 4
local fadeDistanceMin = 2
local function CloseFade(x, y, z)
  -- 2 distance = fully faded
  -- 4 distance = no fade.
  -- linear.
  local vec = vector.new(x, y, z)

  return math.min(math.max(0, (vec:length() - fadeDistanceMin) / fadeDistanceMax), 1) / 2 + 0.000001
end

local lx, ly, lz = 0, 0, 0
local function scanner()
  while true do
    if bIsDisplaying then
      local scan = doScan()

      local ores = pingFor(tOreDict, scan)
      local highlights = pingFor(tOresHighlighted, scan)

      canvas.clear()
      writer(
        string.format("%d ores detected, %d ores highlighted.", ores.n, highlights.n),
        2, 2,
        colors.white,
        colors.black,
        100
      )

      lx, ly, lz = lx % 1, ly % 1, lz % 1

      -- display ores
      highlightCanvas.clear()
      highlightCanvas.recenter()
      oreCanvas.clear()
      oreCanvas.recenter()

      for i = 1, ores.n do
        local ore = ores[i]
        local item = oreCanvas.addItem({ ore.x - lx + 0.5, ore.y - ly + 0.5, ore.z - lz + 0.5 }, ore.name, ore.metadata,
          CloseFade(ore.x, ore.y, ore.z))
        item.setDepthTested(false)
      end

      -- highlight ores
      for i = 1, highlights.n do
        local ore = highlights[i]
        local scale = CloseFade(ore.x, ore.y, ore.z)
        scale = scale + 0.3 * scale + 0.1
        local item = highlightCanvas.addBox(ore.x + 0.5 - lx - scale / 2, ore.y + 0.5 - ly - scale / 2,
          ore.z + 0.5 - lz - scale / 2, scale, scale, scale, 0xffffffff)
        item.setDepthTested(false)
      end
    else
      oreCanvas.clear()
      highlightCanvas.clear()
    end

    os.sleep(0.4)
  end
end

local function gps_er()
  while true do
    local tx, ty, tz = gps.locate()
    if tx then
      lx, ly, lz = tx, ty, tz
    end

    os.sleep(0.4)
  end
end

local function main()
  parallel.waitForAny(menu, scanner, gps_er)
end

local ok, err = pcall(main)
if not ok then
  canvas3d.clear()
  if err ~= "Terminated" then
    error(err, 0)
  else
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
  end
end
