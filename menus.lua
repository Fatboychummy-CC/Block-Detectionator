--- Runs the menus for the shop.

local deep_copy = require "deep_copy"


---@alias colour
---| 'colours.white' # white
---| 'colours.orange' # orange
---| 'colours.magenta' # magenta
---| 'colours.lightBlue' # light blue
---| 'colours.yellow' # yellow
---| 'colours.lime' # lime
---| 'colours.pink' # pink
---| 'colours.grey' # grey
---| 'colours.lightGrey' # light grey
---| 'colours.cyan' # cyan
---| 'colours.purple' # purple
---| 'colours.blue' # blue
---| 'colours.brown' # brown
---| 'colours.green' # green
---| 'colours.red' # red
---| 'colours.black' # black

---@class menu
---@field public addSelection fun(id:string, name:string, description:string|fun(id:string), long_description:string, options:selection_options?) Add a new selection to the menu.
---@field public editSelection fun(id:string, name:string?, description:string|fun(id:string)?, long_description:string?, options:selection_options?) Edit a selection in the menu. Supplied fields will be updated, `nil` fields ignored.
---@field public removeSelection fun(id:string) Remove a selection from the menu.
---@field public getSelection fun(id:string):selection? Get information about a selection.
---@field public clearSelections fun() Clear all selections out of the menu, so selections can be re-added.
---@field public redraw fun() Redraw the menu.
---@field public run fun(id:string?):string Run the menu and return the id of the selection selected. Start with the id passed selected (or the first selection, if nil)
---@field public title string The title of this menu
---@field public win table The window that this menu draws to.
---@field public _selected integer The currently selected index (subtract 1 to make working with it easier: 0 to n-1 instead of 1 to n. For modulo).
---@field public _scroll_position integer The current scroll distance.
---@field public selections selection[]


---@alias selection {id:string, name:string, description:string|fun(id:string), long_description:string}

---@alias selection_options {name_colour:colour?, description_colour:colour?, long_description_colour:colour?, override_width:integer?}

---@class menus
local menus = {}

local function redraw_menu(menu)
  local win = menu.win
  local old = term.redirect(win)

  -- Draw the title.
  term.setCursorPos(1, 1)
  term.setTextColor(colors.yellow)
  term.setBackgroundColor(colors.black)
  term.clear()
  write(menu.title)

  -- Determine how many selections can fit, leaving 3 lines at the bottom.
  -- Two spaces top (title, empty space between)
  -- Three lines bottom
  -- should be h - 5?
  local w, h = term.getSize()
  local selection_count = h - 5

  -- Draw the scroll bar.
  local TOP_POS = 3
  local down_count = math.min(selection_count, #menu.selections)
  if selection_count > down_count then
    for y = TOP_POS + 1, TOP_POS + down_count - 2 do
      term.setCursorPos(1, y)
      term.write("|")
    end
    term.setCursorPos(1, TOP_POS)
    term.write('=')
    term.setCursorPos(1, TOP_POS + down_count - 1)
    term.write('=')
  else
    if down_count == 1 then
      term.setCursorPos(1, TOP_POS)
      term.write('>')
    else
      for y = TOP_POS + 1, TOP_POS + down_count - 2 do
        term.setCursorPos(1, y)
        term.write("|")
      end

      term.setCursorPos(1, TOP_POS)
      term.write('\x1E')
      term.setCursorPos(1, TOP_POS + down_count - 1)
      term.write('\x1F')
    end
  end

  -- Draw the selections.
  term.setTextColor(colors.white)
  for y = TOP_POS, TOP_POS + down_count - 1 do
    local sel_n = y - TOP_POS + 1 + menu._scroll_position
    ---@type selection
    local sel = menu.selections[sel_n]
    if not sel then
      print()
      error(string.format("Bad selection: Got %d, max %d (scroll: %d, select: %d).", sel_n, #menu.selections,
        menu._scroll_position, menu._selected), 0)
    end
    term.setCursorPos(3, y)

    if menu._selected + 1 == sel_n then

      term.setBackgroundColor(colors.gray)
      if sel.options.name_colour then
        term.setTextColor(sel.options.name_colour)
      else
        term.setTextColor(colors.white)
      end
      term.write(string.rep(' ', w))
      term.setCursorPos(3, y)

      if #sel.name > w - (sel.options.override_width or 25) - 4 then
        term.write(sel.name:sub(1, w - (sel.options.override_width or 25) - 7) .. "...")
      else
        term.write(sel.name)
      end

      if sel.options.description_colour then
        term.setTextColor(sel.options.description_colour)
      else
        term.setTextColor(colors.white)
      end
      term.setCursorPos(w - (sel.options.override_width or 25), y)
      term.write(type(sel.description) == "function" and sel.description(sel.id) or sel.description)

      term.setBackgroundColor(colors.black)
      if sel.options.long_description_colour then
        term.setTextColor(sel.options.long_description_colour)
      else
        term.setTextColor(colors.white)
      end
      term.setCursorPos(1, h - 1)
      write(sel.long_description)
    else
      term.setBackgroundColor(colors.black)
      if sel.options.name_colour then
        term.setTextColor(sel.options.name_colour)
      else
        term.setTextColor(colors.white)
      end

      if #sel.name > w - (sel.options.override_width or 25) - 4 then
        term.write(sel.name:sub(1, w - (sel.options.override_width or 25) - 7) .. "...")
      else
        term.write(sel.name)
      end

      if sel.options.description_colour then
        term.setTextColor(sel.options.description_colour)
      else
        term.setTextColor(colors.white)
      end

      term.setCursorPos(w - (sel.options.override_width or 25), y)
      term.write(type(sel.description) == "function" and sel.description(sel.id) or sel.description)
    end
  end

  term.redirect(old)
end

local event_handlers = {
  --- Handle key event
  ---@param menu menu
  ---@param key integer
  key = function(menu, key)
    local _, h = menu.win.getSize()
    if key == keys.up then
      menu._selected = (menu._selected - 1) % #menu.selections

      -- scroll up if needed
      if menu._selected < menu._scroll_position then
        menu._scroll_position = menu._selected
      end

      -- handle wrap-around
      if menu._selected == #menu.selections - 1 then
        menu._scroll_position = #menu.selections - (h - 5)
        if menu._scroll_position < 0 then menu._scroll_position = 0 end
      end
    elseif key == keys.down then
      menu._selected = (menu._selected + 1) % #menu.selections

      -- scroll down if needed
      while menu._selected > menu._scroll_position + (h - 6) do
        menu._scroll_position = menu._scroll_position + 1
      end

      -- handle wrap-around
      if menu._selected == 0 then
        menu._scroll_position = 0
      end
    elseif key == keys.enter then
      return true
    end
  end,
  menu_redraw = function() end -- this is just here to cause a redraw to occur
}

--- Handle an event for a given menu.
---@param menu menu The menu to handle events for.
---@param event_name string The name of the event.
---@param ... any The event parameters.
local function handle_menu_event(menu, event_name, ...)
  if menu.win.isVisible() and event_handlers[event_name] then
    local result = event_handlers[event_name](menu, ...)

    if not result then
      redraw_menu(menu)
    end

    return result
  end
end

--- Create a new menu object
---@param win table The window to draw to.
---@param title string The title of the menu.
---@return menu menu The menu object.
function menus.create(win, title)
  ---@class menu
  local menu = {
    selections = {},
    win = win,
    title = title,
    _selected = 0,
    _scroll_position = 0
  }

  function menu.redraw()
    redraw_menu(menu)
  end

  function menu.addSelection(id, name, description, long_description, options)
    table.insert(menu.selections,
      { id = id, name = name, description = description, long_description = long_description, options = options or {} })
  end

  function menu.editSelection(id, name, description, long_description, options)
    for _, selection in ipairs(menu.selections) do
      if selection.id == id then
        selection.name = name or selection.name
        selection.description = description or selection.description
        selection.long_description = long_description or selection.long_description
        selection.options = options or selection.options

        menu.redraw()
        return
      end
    end
  end

  function menu.removeSelection(id)
    for i, selection in ipairs(menu.selections) do
      if selection.id == id then
        table.remove(menu.selections, i)

        -- protect from overflowing on removal.
        menu._scroll_position = 0
        menu._selected = 0

        os.queueEvent("menu_redraw")
        return
      end
    end
  end

  function menu.getSelection(id)
    for _, selection in ipairs(menu.selections) do
      if selection.id == id then
        return deep_copy(selection)
      end
    end
  end

  function menu.clearSelections()
    menu.selections = {}
    menu.redraw()
  end

  function menu.run()
    redraw_menu(menu)
    while true do
      if handle_menu_event(menu, coroutine.yield()) then
        if not menu.selections[menu._selected + 1] then
          error(("Bad selection on return: %d of a max %d"):format(menu._selected + 1, #menu.selections), 0)
        end
        return menu.selections[menu._selected + 1].id
      end
    end
  end

  return menu
end

--- Ask the user a question and get them to input a value.
---@param win table The window to be used.
---@param title string The title of the page.
---@param question string The question to ask.
---@return string answer The answer the user gave
function menus.question(win, title, question)
  local old = term.redirect(win)

  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.yellow)
  term.clear()
  term.setCursorPos(1, 1)
  write(title)

  term.setCursorPos(1, 3)
  print(question)

  write("> ")
  term.setTextColor(colors.white)

  local answer = read()

  term.redirect(old)
  return answer
end

return menus
