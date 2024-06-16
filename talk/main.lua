local Lanes = require("lanes").configure()

local function version()
  return "Kagari_as_Plugin/1.0.0"
end

local target  = nil
local result  = nil
local filetype = nil

local Process = require("process")

local function getJson(url)
  -- 必要なモジュールはここ(別スレッド内)で呼ぶこと
  local HTTP  = require("socket.http")
  local LTN12 = require("ltn12")
  local JSON  = require("json")

  local t = {}
  HTTP.request({
    method  = "GET",
    url     = url,
    sink    = LTN12.sink.table(t),
  })
  local data  = table.concat(t)
  local json  = JSON.decode(data)
  return json
end

local function getZip(url)
  local HTTP  = require("socket.http")
  local LTN12 = require("ltn12")

  local t = {}
  HTTP.request({
    method  = "GET",
    url     = url,
    sink    = LTN12.sink.table(t),
  })
  local data  = table.concat(t)
  return data
end

local function bootNoka(__)
  local p = Process({
    command = __("_path") .. "noka/noka.exe",
    chdir = true,
    hide = false,
  })
  p:spawn()
  __("_Process", p)
end

return {
  {
    id  = "version",
    passthrough = true,
    content = function(plugin, ref)
      return {
        Value = "1.0.0"
      }
    end,
  },
  {
    id = "OnUnload",
    content = function(plugin, ref)
      local __ = plugin.var
      local p = __("_Process")
      if p ~= nil then
        p:despawn()
        __("_Process", nil)
      end
    end,
  },
  {
    id  = "OnSecondChange",
    content = function(plugin, ref)
      if result then
        if result.status == "done" then
          local __ = plugin.var
          if filetype == "json" then
            local json  = result[1]
            local isUpdated = false
            local updated_at_saved = __("updated_at")
            local updated_at_fetched = json.assets[1]["updated_at"]
            local pattern = "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z"
            local runyear, runmonth, runday, runhour, runminute, runseconds = string.match(updated_at_fetched, pattern)
            local convertedTimestampFetched = os.time({year = runyear, month = runmonth, day = runday, hour = runhour, min = runminute, sec = runseconds})
            if not(updated_at_saved) then
              isUpdated = true
            else
              local runyear2, runmonth2, runday2, runhour2, runminute2, runseconds2 = string.match(updated_at_saved, pattern)
              local convertedTimestampSaved = os.time({year = runyear2, month = runmonth2, day = runday2, hour = runhour2, min = runminute2, sec = runseconds2})
              if convertedTimestampFetched > convertedTimestampSaved then
                isUpdated = true
              end
            end
            if isUpdated then
              __("_updated_at", updated_at_fetched)
              filetype = "zip"
              local func  = Lanes.gen("*", {}, getZip)
              local url = json.assets[1]["browser_download_url"]
              result  = func(url)
              return nil
            else
              filetype = nil
              result  = nil
              bootNoka(__)
              return nil
            end
          elseif filetype == "zip" then
            filetype = nil
            local zip  = result[1]
            result  = nil
            local filepath = __("_path") .. "noka.zip"
            local fh  = io.open(filepath, "wb")
            fh:write(zip)
            fh:close()
            local dirpath = __("_path")
            local Misc  = require("ukagaka_misc")
            Misc.sendSSTP(__("_uniqueid"), "EXECUTE SSTP/1.1\r\nCharset: UTF-8\r\nSender: Kagari\r\nCommand: ExtractArchive\r\nReference0: " .. filepath .. "\r\nReference1: " .. dirpath .. "\r\n\r\n")
            __("updated_at", __("_updated_at"))
            bootNoka(__)
          end
        end
      end
      return nil
    end
  },
  {
    id  = "OnMenuExec",
    content = function(plugin, ref)
      local __ = plugin.var
      __("_uniqueid", ref("Reference3"))
      target  = ref("Sender")
      if __("_Process") == nil then
        if not(result) then
          filetype = "json"
          local func  = Lanes.gen("*", {}, getJson)
          local url = "https://api.github.com/repos/betonetojp/noka/releases/latest"
          result  = func(url)
        end
      else
        local p = __("_Process")
        p:spawn()
      end
      return nil
    end,
  },
}
