-- うっかりグローバル変数を宣言したりするので確認用。
setmetatable(_G, {
  __newindex  = function(t, k, v)
    -- sol.から始まるのはまあ大体意図的なものなので無視
    if string.sub(k, 1, 4) ~= "sol." then
      print(debug.traceback("WARNING: attempt to write to undeclared variable: " .. tostring(k), 2))
    end
    rawset(t, k, v)
  end,
  __index = function(t, k)
    -- sol.から始まるのはまあ大体意図的なものなので無視
    if string.sub(k, 1, 4) ~= "sol." then
      print(debug.traceback("WARNING: attempt to read undeclared variable: " .. tostring(k), 2))
    end
  end,
})

local Plugin    = require("plugin")
local Module    = require("ukagaka_module.plugin")
local Request   = Module.Request

local plugin  = nil

local M = {}

function M.load(path)
  print("load")
  plugin  = Plugin()
  plugin:load(path)
  return true
end

function M.request(str)
  local req = Request.parse(str)
  local res = plugin:request(req)
  return res:tostring()
end

function M.unload()
  plugin:unload()
  return true
end

function M.debug()
  return plugin
end

return M
