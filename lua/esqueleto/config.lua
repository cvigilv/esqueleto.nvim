---@module "esqueleto.config"
---@author Carlos Vigil-Vásquez
---@license MIT

local utils = require("esqueleto.utils")

---@class Esqueleto.Config
---@field autouse boolean Automatically use templates if its the only one available
---@field directories string[] Directories to search for templates
---@field patterns function Function to get patterns from a directory
---@field wildcards Esqueleto.WildcardConfig Configuration for wildcard expansion
---@field advanced Esqueleto.AdvancedConfig Advanced configuration options

---@class Esqueleto.WildcardConfig
---@field expand boolean Enable wildcard expansion
---@field lookup table<string, function|string> Lookup table for wildcard functions

---@class Esqueleto.AdvancedConfig
---@field ignored string[] Ignored files or patterns
---@field ignore_os_files boolean Ignore OS-specific files

---@type Esqueleto.Config
local defaults = {
  autouse = true,
  directories = { vim.fn.stdpath("config") .. "/skeletons" },
  patterns = function(dir) return vim.fn.readdir(dir) end,
  wildcards = {
    expand = true,
    lookup = {
      -- File
      ["filename"] = function() return vim.fn.expand("%:t:r") end,
      ["fileabspath"] = function() return vim.fn.expand("%:p") end,
      ["filerelpath"] = function() return vim.fn.expand("%:p:~") end,
      ["fileext"] = function() return vim.fn.expand("%:e") end,
      ["filetype"] = function() return vim.bo.filetype end,

      -- Date and time
      ["date"] = function() return os.date("%Y%m%d", os.time()) end,
      ["year"] = function() return os.date("%Y", os.time()) end,
      ["month"] = function() return os.date("%m", os.time()) end,
      ["day"] = function() return os.date("%d", os.time()) end,
      ["time"] = function() return os.date("%T", os.time()) end,

      -- System
      ["host"] = function() return utils.capture("hostname", false) end,
      ["user"] = function() return os.getenv("USER") end,

      -- Github
      ["gh-email"] = function() return utils.capture("git config user.email", false) end,
      ["gh-user"] = function() return utils.capture("git config user.name", false) end,
    },
  },
  advanced = {
    ignored = {},
    ignore_os_files = true,
  },
}

local M = {}

--- Update default configuration table by merging with user's configuration table
---@param config Esqueleto.Config user configuration table
---@return Esqueleto.Config
M.update_config = function(config)
  vim.validate({ config = { config, "table", true } })

  config = vim.tbl_deep_extend("force", defaults, config or {})

  -- Validate setup
  vim.validate({
    ["autouse"] = { config.autouse, "boolean" },
    ["directories"] = { config.directories, { "table", "string" } },
    ["patterns"] = { config.patterns, { "table", "function" } },
    ["wildcards"] = { config.wildcards, "table" },
    ["wildcards.expand"] = { config.wildcards.expand, "boolean" },
    ["wildcards.lookup"] = { config.wildcards.lookup, "table" },
    ["advanced"] = { config.advanced, "table" },
    ["advanced.ignored"] = { config.advanced.ignored, { "table", "function" } },
    ["advanced.ignore_os_files"] = { config.advanced.ignore_os_files, "boolean" },
  })

  return config
end

return M
