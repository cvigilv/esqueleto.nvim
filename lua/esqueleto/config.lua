---@module "esqueleto.config"
---@author Carlos Vigil-Vásquez
---@license MIT

---@class Esqueleto.Config
---@field autouse boolean Automatically use templates if its the only one available
---@field directories string|table<string> Directory or directories to search for templates
---@field patterns function|table<string> Function to get patterns from a directory or list of patterns
---@field wildcards Esqueleto.WildcardConfig Wildcard configuration options
---@field advanced Esqueleto.AdvancedConfig Advanced configuration options

---@class Esqueleto.WildcardConfig
---@field expand boolean Enable wildcard expansion
---@field lookup table<string, function|string> Lookup table for wildcards

---@class Esqueleto.Advanced.IgnoreRulesConfig
---@field templates table Options related to template ignoring
---@field filenames table<string> File name patterns to ignore
---@field filetypes table<string> File type patterns to ignore

---@class Esqueleto.AdvancedConfig
---@field logging table Logging options
---@field ignore_rules Esqueleto.Advanced.IgnoreRulesConfig Ignore rules options

---@type Esqueleto.Config
local defaults = {
  autouse = true,
  directories = { vim.fn.stdpath("config") .. "/skeletons" },
  patterns = function(dir) return vim.fn.readdir(dir) end,
  wildcards = {
    expand = true,
    lookup = require("esqueleto.helpers.wildcards").builtin,
  },
  advanced = {
    ignore_rules = {
      templates = {
        include_os_files = true,
        extras = {},
      },
      filenames = {},
      filetypes = {},
    },

    logging = {
      use_console = false, -- Whether to print the output to neovim while running (one of 'sync','async' or false)
      use_file = true, -- Hwther to write logs to a file (`stdpath("cache")/esqueleto_nvim.log`)
      use_quickfix = false, -- Whether to write logs to the quickfix list
      level = "trace", -- Any messages above this level will be logged (one of "trace", "debug", "info", "warn", "error" or "fatal")
    },
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

    ["advanced.ignore_rules"] = { config.advanced.ignore_rules, "table" },
    ["advanced.ignore_rules.templates"] = { config.advanced.ignore_rules.templates, "table" },
    ["advanced.ignore_rules.templates.include_os_files"] = {
      config.advanced.ignore_rules.templates.include_os_files,
      "boolean",
    },
    ["advanced.ignore_rules.templates.extras"] = {
      config.advanced.ignore_rules.templates.extras,
      { "function", "table" },
    },
    ["advanced.ignore_rules.filenames"] = { config.advanced.ignore_rules.filenames, "table" },
    ["advanced.ignore_rules.filetypes"] = { config.advanced.ignore_rules.filetypes, "table" },

    ["advanced.logging.use_console"] = {
      config.advanced.logging.use_console,
      { "string", "boolean" },
    },
    ["advanced.logging.use_file"] = { config.advanced.logging.use_file, { "boolean" } },
    ["advanced.logging.use_quickfix"] = { config.advanced.logging.use_quickfix, { "boolean" } },
    ["advanced.logging.level"] = { config.advanced.logging.level, { "string" } },
  })

  -- Add logging function
  config.advanced.logging.func = require("esqueleto.log").new(config.advanced.logging, true)
  config.advanced.logging.func.info("Updated default configuration with user options.")

  return config
end

return M
