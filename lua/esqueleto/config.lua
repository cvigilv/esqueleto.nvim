local M = {}

M.default_config = {
  autouse = true,
  directories = { vim.fn.stdpath("config") .. "/skeletons" },
  patterns = {},
}

M.updateconfig = function(config)
  vim.validate({ config = { config, 'table', true } })
  config = vim.tbl_deep_extend('force', M.default_config, config or {})

  -- Validate setup
  vim.validate({
    autouse = { config.autouse, 'boolean' },
    directories = { config.directories, 'table' },
    patterns = { config.patterns, 'table' },
  })

  return config
end

return M
