---@diagnostic disable: undefined-global, lowercase-global, undefined-field

local eq = assert.are.same

describe("`update_config`", function()
  before_each(function() config = require("esqueleto.config") end)

  it("should return defaults whenever the configuration table is empty", function()
    local expected_defaults = {
      autouse = true,
      directories = { vim.fn.stdpath("config") .. "/skeletons" },
      patterns = true,
      wildcards = {
        expand = true,
        lookup = true,
      },
      advanced = {
        ignored = {},
        ignore_os_files = true,
        ignore_patterns = { "^/tmp", ".bak$" },
      },
    }

    ---@diagnostic disable-next-line: missing-fields
    observed_opts = config.update_config({})
    observed_opts.wildcards.lookup = true -- We are skipping comparing functions since it's difficult
    observed_opts.patterns = true -- We are skipping comparing functions since it's difficult
    eq(observed_opts, expected_defaults)
  end)

  it("should return updated configuration table", function()
    local expected_opts = {
      autouse = false,
      directories = { vim.fn.stdpath("config") .. "/skeletons" },
      patterns = { "foo", "bar", "baz" },
      wildcards = { expand = false, lookup = { foo = "bar" } },
      advanced = { ignored = {}, ignore_patterns = { "^/tmp", ".bak$" }, ignore_os_files = true },
    }

    ---@diagnostic disable-next-line: missing-fields
    observed_opts = config.update_config({
      autouse = false,
      patterns = { "foo", "bar", "baz" },
      wildcards = { expand = false, lookup = { foo = "bar" } },
    })
    eq(observed_opts, expected_opts)
  end)
end)
