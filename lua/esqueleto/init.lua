local autocmd = require('esqueleto.autocmd')
local excmd = require('esqueleto.excmd')
local config = require('esqueleto.config')
local utils = require('esqueleto.utils')
local ui = require('esqueleto.ui')

_G.esqueleto_inserted_at = {}

local M = {}

M.inserttemplate = function(opts)
  -- Get pattern alternatives for current file
  local filepath = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local filetype = vim.bo.filetype

  -- Identify if pattern matches user configuration
  local pattern = nil
  if not _G.esqueleto_inserted_at[filepath] then
    -- match either filename or extension. Filename has priority
    if vim.tbl_contains(opts.patterns, filename) then
      pattern = filename
    elseif vim.tbl_contains(opts.patterns, filetype) then
      pattern = filetype
    end

    -- Get templates for selected pattern
    local templates = utils.gettemplates(pattern, opts.directories)

    -- Pop-up selection UI
    ui.selecttemplate(templates, opts)
    _G.esqueleto_inserted_at[filepath] = true
  end
end

M.setup = function(opts)
  -- update defaults
  opts = config.updateconfig(opts)

  -- Module functionality
  autocmd.createautocmd(M.inserttemplate, opts)
  excmd.createexcmd(M.inserttemplate, opts)
end

return M
