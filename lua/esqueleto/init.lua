local log = require("esqueleto.log")

_G.esqueleto_inserted = {}

local M = {}

--- Setup `esqueleto.nvim`
---@param opts Esqueleto.Config User configuration table
M.setup = function(opts)
  log.info("Load modules")
  local autocmd = require("esqueleto.autocmd")
  local config = require("esqueleto.config")
  local excmd = require("esqueleto.excmd")

  -- update defaults
  log.info("Update configuration with user options")
  opts = config.update_config(opts)

  -- Module functionality
  log.info("Create autocmds and excmds")
  autocmd.createautocmd(opts)
  excmd.createexcmd(opts)
end

return M
