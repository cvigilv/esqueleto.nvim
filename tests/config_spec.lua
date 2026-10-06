---@diagnostic disable: undefined-global, lowercase-global, undefined-field

local eq = assert.are.same
local is_nil = assert.is_nil

local config = require("esqueleto.config")
local original_deprecate
local deprecations

local function update(opts) return config.update_config(opts) end

local function find_deprecation(name)
  for _, call in ipairs(deprecations) do
    if call.name == name then return call end
  end
end

describe("`update_config`", function()
  before_each(function()
    original_deprecate = vim.deprecate
    deprecations = {}
    vim.deprecate = function(name, alternative, version, plugin)
      table.insert(deprecations, {
        name = name,
        alternative = alternative,
        version = version,
        plugin = plugin,
      })
    end
  end)

  after_each(function() vim.deprecate = original_deprecate end)

  it("returns canonical defaults", function()
    local observed = vim.deepcopy(update({}))
    observed.wildcards.lookup = true
    observed.patterns = true

    eq(observed, {
      autouse = true,
      directories = { vim.fn.stdpath("config") .. "/skeletons" },
      patterns = true,
      wildcards = {
        expand = true,
        lookup = true,
      },
      advanced = {
        ignored_templates = {},
        ignored_patterns = {},
        ignore_os_files = true,
      },
    })
    is_nil(find_deprecation("advanced.ignored"))
    is_nil(find_deprecation("advanced.ignore_patterns"))
  end)

  it("accepts canonical options without deprecation notices", function()
    local ignored_templates = function() return false end
    local observed = update({
      advanced = {
        ignored_templates = ignored_templates,
        ignored_patterns = { "^/tmp/", "Luapad%.lua$" },
      },
    })

    eq(observed.advanced.ignored_templates, ignored_templates)
    eq(observed.advanced.ignored_patterns, { "^/tmp/", "Luapad%.lua$" })
    is_nil(find_deprecation("advanced.ignored"))
    is_nil(find_deprecation("advanced.ignore_patterns"))
  end)

  it("migrates `advanced.ignored`", function()
    local observed = update({ advanced = { ignored = { "*.bak" } } })

    eq(observed.advanced.ignored_templates, { "*.bak" })
    is_nil(observed.advanced.ignored)
    eq(find_deprecation("advanced.ignored"), {
      name = "advanced.ignored",
      alternative = "advanced.ignored_templates",
      version = "2.0.0",
      plugin = "esqueleto.nvim",
    })
  end)

  it("migrates `advanced.ignore_patterns`", function()
    local observed = update({ advanced = { ignore_patterns = { "Claudio" } } })

    eq(observed.advanced.ignored_patterns, { "Claudio" })
    is_nil(observed.advanced.ignore_patterns)
    eq(find_deprecation("advanced.ignore_patterns"), {
      name = "advanced.ignore_patterns",
      alternative = "advanced.ignored_patterns",
      version = "2.0.0",
      plugin = "esqueleto.nvim",
    })
  end)

  it("rejects old and new template options together", function()
    assert.has_error(
      function() update({ advanced = { ignored = {}, ignored_templates = {} } }) end,
      "`advanced.ignored` and `advanced.ignored_templates` cannot be used together"
    )
  end)

  it("rejects old and new destination options together", function()
    assert.has_error(
      function() update({ advanced = { ignore_patterns = {}, ignored_patterns = {} } }) end,
      "`advanced.ignore_patterns` and `advanced.ignored_patterns` cannot be used together"
    )
  end)

  it("rejects invalid template ignore lists", function()
    assert.has_error(
      function() update({ advanced = { ignored_templates = { 1 } } }) end,
      "`advanced.ignored_templates[1]` must be a string"
    )
    assert.has_error(
      function() update({ advanced = { ignored_templates = { pattern = "*.bak" } } }) end,
      "`advanced.ignored_templates` must be a list"
    )
  end)

  it("rejects invalid destination ignore lists", function()
    assert.has_error(
      function() update({ advanced = { ignored_patterns = { 1 } } }) end,
      "`advanced.ignored_patterns[1]` must be a string"
    )
    assert.has_error(
      function() update({ advanced = { ignored_patterns = { pattern = "^/tmp" } } }) end,
      "`advanced.ignored_patterns` must be a list"
    )
  end)

  it("rejects malformed Lua patterns", function()
    assert.has_error(function() update({ advanced = { ignored_patterns = { "%" } } }) end)
  end)
end)
