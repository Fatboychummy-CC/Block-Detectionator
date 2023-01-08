--- Deep copy a table.
---@param t table The table to be copied
---@return table copied The copied table
local function deep_copy(t)
  local tnew = {}

  if type(t) ~= "table" then return t end

  for k, v in pairs(t) do
    if type(v) == "table" then
      tnew[k] = deep_copy(v)
    else
      tnew[k] = v
    end
  end

  return tnew
end

return deep_copy
