local selector = require("esqueleto.selectors.builtin")
local utils = require("esqueleto.utils")
local M = {}

---@type Esqueleto.Config
M.default_config = {
  autouse = true,
  directories = { vim.fn.stdpath("config") .. "/skeletons" },
  patterns = {},
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
      ["date"] = function()
        return os.date("%Y%m%d", os.time()) --[[@as string]]
      end,
      ["year"] = function()
        return os.date("%Y", os.time()) --[[@as string]]
      end,
      ["month"] = function()
        return os.date("%m", os.time()) --[[@as string]]
      end,
      ["day"] = function()
        return os.date("%d", os.time()) --[[@as string]]
      end,
      ["time"] = function()
        return os.date("%T", os.time()) --[[@as string]]
      end,

      -- System
      ["host"] = utils.capture("hostname", false),
      ["user"] = os.getenv("USER") or "USER",

      -- Github
      ["gh-email"] = utils.capture("git config user.email", false),
      ["gh-user"] = utils.capture("git config user.name", false),
    },
  },
  selector = selector,
  advanced = {
    ignored = {},
    ignore_os_files = true,
  },
}

---Update default configuration table by merging with user's configuration table
---@param config Esqueleto.Config user configuration table
---@return Esqueleto.Config
M.updateconfig = function(config)
  vim.validate({ config = { config, "table", true } })
  config = vim.tbl_deep_extend("force", M.default_config, config or {})

  -- Validate setup
  vim.validate({
    autouse = { config.autouse, "boolean" },
    directories = { config.directories, "table" },
    patterns = { config.patterns, "table" },
    wildcards = { config.wildcards, "table" },
    advanced = { config.advanced, "table" },
    ["advanced.ignored"] = { config.advanced.ignored, { "table", "function" } },
    ["advanced.ignore_os_files"] = { config.advanced.ignore_os_files, "boolean" },
  })

  return config
end

return M
