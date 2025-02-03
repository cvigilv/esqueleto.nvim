---@diagnostic disable: undefined-global, lowercase-global, undefined-field

-- NOTE: refer to https://github.com/lunarmodules/luassert/tree/master for more info and examples
local eq = assert.are.same
local is_true = assert.is.True
local throws_error = assert.has_error

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
      advanced = { ignored = {}, ignore_os_files = true },
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
