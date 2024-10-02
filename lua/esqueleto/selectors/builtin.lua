return function(templates)
  -- Sync call ui.select
  -- See: https://github.com/mfussenegger/nvim-dap/blob/66d33b7585b42b7eac20559f1551524287ded353/lua/dap/ui.lua#L55
  local co = coroutine.running()
  local choicer = function(choice)
    if not choice then
      vim.notify("[esqueleto] No template selected, leaving buffer empty", vim.log.levels.INFO)
    end
    coroutine.resume(co, choice)
  end
  -- I don't know reason to use that
  choicer = vim.schedule_wrap(choicer)
  vim.ui.select(vim.tbl_keys(templates), { prompt = "Select skeleton to use:" }, choicer)
  return coroutine.yield()
end
