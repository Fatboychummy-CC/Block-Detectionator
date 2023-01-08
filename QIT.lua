---@class QIT
return function()
  return {
    n = 0,

    --- Insert a value into the QIT at the end.
    ---@param self QIT
    ---@param value any The value to be inserted.
    Insert = function(self, value)
      self.n = self.n + 1
      self[self.n] = value
    end,

    --- Insert a value into the QIT at the beginning.
    ---@param self QIT
    ---@param value any The value to be inserted.
    Push = function(self, value)
      table.insert(self, 1, value)
      self.n = self.n + 1
    end,

    --- Remove a value from the end of the QIT.
    ---@param self QIT
    ---@return any value The value removed.
    Remove = function(self)
      if self.n > 0 then
        local value = self[self.n]
        self[self.n] = nil
        self.n = self.n - 1

        return value
      end
    end,

    --- Remove a value from the beginning of the QIT.
    ---@param self QIT
    ---@return any value The value removed.
    Drop = function(self)
      local value = table.remove(self, 1)

      if value ~= nil then
        self.n = self.n - 1
      end

      return value
    end,

    --- Remove all extra fields so this is just a normal array.
    ---@param self QIT
    ---@return self self
    Clean = function(self)
      self.Insert = nil
      self.Push = nil
      self.Remove = nil
      self.Drop = nil
      self.Clean = nil

      return self
    end
  }
end
