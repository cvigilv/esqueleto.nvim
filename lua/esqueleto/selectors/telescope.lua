return function(templates)
  local co = coroutine.running()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  pickers
    .new({}, {
      prompt_title = "Templates",
      previewer = _TelescopeConfigurationValues.file_previewer({}),
      finder = finders.new_table({
        results = vim.tbl_keys(templates),
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry,
            ordinal = entry,
            filename = templates[entry],
          }
        end,
      }),
      sorter = _TelescopeConfigurationValues.generic_sorcer({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          coroutine.resume(co, selection.value)
        end)
        return true
      end,
    })
    :find()
  return coroutine.yield()
end
