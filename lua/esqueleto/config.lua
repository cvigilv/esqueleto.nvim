local M = {}

-- Extend 'os' to be able to capture stdout from execute
function M.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', '')
  return s
end

M.default_config = {
  autouse = true,
  directories = { vim.fn.stdpath("config") .. "/skeletons" },
  patterns = {},
  wildcards = {
    expand = true,
    lookup = {
      -- File
      ["filename"] = vim.fn.expand("%:t:r"),
      ["filepath"] = vim.fn.expand("%:f"),

      -- Date and time
      ["date"] = os.date("%Y%m%d", os.time()),
      ["year"] = os.date("%Y", os.time()),
      ["month"] = os.date("%m", os.time()),
      ["day"] = os.date("%d", os.time()),
      ["time"] = os.date("%T", os.time()),

      -- System
      ["host"] = os.getenv("HOSTNAME"),
      ["user"] = os.getenv("USER"),

      -- Github
      ["gh-email"] = M.capture("git config user.email", false),
      ["gh-user"] = M.capture("git config user.name", false),
    },
  },
}

M.updateconfig = function(config)
  vim.validate({ config = { config, "table", true } })
  config = vim.tbl_deep_extend("force", M.default_config, config or {})

  -- Validate setup
  vim.validate({
    autouse = { config.autouse, "boolean" },
    directories = { config.directories, "table" },
    patterns = { config.patterns, "table" },
    wildcards = { config.wildcards, "table" },
  })

  return config
end

return M
