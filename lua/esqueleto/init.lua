_G.esqueleto_inserted = {}

local autocmd = require("esqueleto.autocmd")
local config = require("esqueleto.config")
local excmd = require("esqueleto.excmd")

---@alias Wildcard { [string] : string | fun():string }
---@class Wildcards
---@field lookup Wildcard
---@field expand boolean Replace ${} with an instance of a wildcards array?

---@class Esqueleto.Advanced
---@field ignored string[] | fun(file:string):boolean Array of glob file filters
---@field ignore_os_files boolean To ignore OS files?

---@class Esqueleto.Config
---@field directories string[]  The list of paths in which the search will be performed
---@field patterns string[] See: [vim.api.nvim_create_autocmd](lua://vim.api.nvim_create_autocmd)
---@field autouse boolean Auto-use a template?
---@field selector fun( templatenames: string[] ):string? Function that choose some of template
---@field wildcards Wildcards
---@field advanced Esqueleto.Advanced

local M = {}

--- Setup `esqueleto.nvim`
---@param opts Esqueleto.Config User configuration table
M.setup = function(opts)
  -- update defaults
  opts = config.updateconfig(opts)

  -- Module functionality
  autocmd.createautocmd(opts)
  excmd.createexcmd(opts)
end

return M
