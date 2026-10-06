---@module "esqueleto.config"
---@author Carlos Vigil-Vásquez
---@license MIT

local utils = require("esqueleto.core")

---@class Esqueleto.Config
---@field autouse boolean Automatically use templates if its the only one available
---@field directories string|table<string> Directory or directories to search for templates
---@field patterns function|table<string> Function to get patterns from a directory or list of patterns
---@field wildcards Esqueleto.WildcardConfig Wildcard configuration options
---@field advanced Esqueleto.AdvancedConfig Advanced configuration options

---@class Esqueleto.WildcardConfig
---@field expand boolean Enable wildcard expansion
---@field lookup table<string, function|string> Lookup table for wildcards

---@class Esqueleto.AdvancedConfig
---@field ignored_templates function|table<string> Glob patterns or predicate used to exclude template files
---@field ignored_patterns string[] Lua patterns used to suppress automatic insertion by destination path
---@field ignore_os_files boolean Ignore OS-specific template files

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
    ignored_templates = {},
    ignored_patterns = {},
    ignore_os_files = true,
  },
}

local M = {}

local deprecated_advanced_options = {
  { old = "ignored", new = "ignored_templates" },
  { old = "ignore_patterns", new = "ignored_patterns" },
}

local migrate_deprecated_options = function(config)
  config = vim.deepcopy(config or {})
  if type(config.advanced) ~= "table" then return config end

  for _, option in ipairs(deprecated_advanced_options) do
    local old_name = option.old
    local new_name = option.new
    local old_value = config.advanced[old_name]
    local new_value = config.advanced[new_name]

    if old_value ~= nil and new_value ~= nil then
      error(
        string.format(
          "`advanced.%s` and `advanced.%s` cannot be used together",
          old_name,
          new_name
        ),
        0
      )
    end

    if old_value ~= nil then
      vim.deprecate("advanced." .. old_name, "advanced." .. new_name, "2.0.0", "esqueleto.nvim")
      config.advanced[new_name] = old_value
      config.advanced[old_name] = nil
    end
  end

  return config
end

local validate_string_list = function(name, values)
  if not vim.islist(values) then error("`" .. name .. "` must be a list", 0) end

  for index, value in ipairs(values) do
    if type(value) ~= "string" then
      error(string.format("`%s[%d]` must be a string", name, index), 0)
    end
  end
end

local validate_lua_patterns = function(patterns)
  validate_string_list("advanced.ignored_patterns", patterns)

  for index, pattern in ipairs(patterns) do
    local valid, message = pcall(string.find, "", pattern)
    if not valid then
      error(
        string.format(
          "`advanced.ignored_patterns[%d]` is not a valid Lua pattern: %s",
          index,
          message
        ),
        0
      )
    end
  end
end

--- Update default configuration table by merging with user's configuration table
---@param config Esqueleto.Config user configuration table
---@return Esqueleto.Config
M.update_config = function(config)
  vim.validate({ config = { config, "table", true } })

  config = migrate_deprecated_options(config)
  config = vim.tbl_deep_extend("force", defaults, config)

  -- Validate setup
  vim.validate({
    ["autouse"] = { config.autouse, "boolean" },
    ["directories"] = { config.directories, { "table", "string" } },
    ["patterns"] = { config.patterns, { "table", "function" } },
    ["wildcards"] = { config.wildcards, "table" },
    ["wildcards.expand"] = { config.wildcards.expand, "boolean" },
    ["wildcards.lookup"] = { config.wildcards.lookup, "table" },
    ["advanced"] = { config.advanced, "table" },
    ["advanced.ignored_templates"] = {
      config.advanced.ignored_templates,
      { "table", "function" },
    },
    ["advanced.ignored_patterns"] = { config.advanced.ignored_patterns, "table" },
    ["advanced.ignore_os_files"] = { config.advanced.ignore_os_files, "boolean" },
  })

  if type(config.advanced.ignored_templates) == "table" then
    validate_string_list("advanced.ignored_templates", config.advanced.ignored_templates)
  end
  validate_lua_patterns(config.advanced.ignored_patterns)

  return config
end

return M
