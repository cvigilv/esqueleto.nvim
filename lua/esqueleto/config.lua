local M = {}

M.default_config = {
  autouse = true,
  directories = { vim.fn.stdpath("config") .. "/skeletons" },
  patterns = {},
<<<<<<< HEAD
  use_os_ignore = true,
  extra_ignore = {},
=======
  advanced = {
    ignored = {},
    ignore_os_files = true,
  }
>>>>>>> origin/main
}

M.updateconfig = function(config)
  vim.validate({ config = { config, 'table', true } })
  config = vim.tbl_deep_extend('force', M.default_config, config or {})

  -- Validate setup
  vim.validate({
    autouse = { config.autouse, 'boolean' },
    directories = { config.directories, 'table' },
    patterns = { config.patterns, 'table' },
<<<<<<< HEAD
    use_os_ignore = { config.use_os_ignore, 'boolean' },
    extra_ignore = { config.extra_ignore, { 'table', 'function' } },
=======
    advanced = { config.advanced, 'table' },
    ["advanced.ignored"] = { config.advanced.ignored, { 'table', 'function' } },
    ["advanced.ignore_os_files"] = { config.advanced.ignore_os_files, 'boolean' },
>>>>>>> origin/main
  })

  return config
end

return M
