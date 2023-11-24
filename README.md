# esqueleto.nvim

Reduce your boilerplate code the lazy-bones way.

## What is `esqueleto`?

![Preview](https://i.imgur.com/MBMkSF7.gif)

`esqueleto.nvim` is a minimal plugin that intends to make the use of templates
or "skeletons" as easy and straightforward as possible. This package adds a prompt
for inserting a specific template when creating a new file that matches a specific
file name or pattern.

## Installation

Install `esqueleto.nvim` with your preferred package manager:

[packer](https://github.com/wbthomason/packer.nvim)

```lua
-- Stable
use 'cvigilv/esqueleto.nvim'

-- Development (latest)
use { 'cvigilv/esqueleto.nvim', branch = "develop" }
```

[lazy](https://github.com/folke/lazy.nvim)

```lua
-- Stable
{
  dir = "cvigilv/esqueleto.nvim",
  config = function()
    require("esqueleto").setup({
        -- Your configuration goes here...
      }
    )
  end,
},

-- Development (latest)
{
  dir = "cvigilv/esqueleto.nvim",
  branch = "develop",
  config = function()
    require("esqueleto").setup(
      {
        -- Your configuration goes here...
      }
    )
  end,
}
```

## Usage & configuration

To configure `esqueleto.nvim` and use it, the following should be present in
your `init.lua`:
```lua
require("esqueleto").setup(
  {
    -- Whether to auto-use a template if it's the only one for a pattern
    autouse = true,

    -- Directories to check for file templates
    directories = {"~/.config/nvim/skeletons/", "~/.config/nvim/work_skeletons/"},

    -- Patterns to match when creating new file, can be either (i) file names or
    -- (ii) file types (exact file name match have priority over file types).
    patterns = { "README.md", "python" },

    -- Wildcards expansion options and look-up table
    wildcards = {
      expand = true, -- whether to expand wildcards
      lookup = { -- This can be either:
        -- (i) a string,
        ["signature"] = "Signed: My cool name",
        -- or (ii) a function.
        ["random_number"] = function() return math.random() end,
      }
    }

    -- Advanced `esqueleto.nvim` options
    advanced = {
      -- List of files glob patterns to ignore or a function that determines if a
      -- file should be ignored.
      ignored = {},

      -- Ignore OS-generated files (e.g. `.DS_Store`)
      ignore_os_files = true,
    },
  }
)
```
For more information, refer to docs (`:h esqueleto`). For example skeleton files,
check [the `skeletons` folder](skeletons/).

The default options of `esqueleto` are
```lua
{
  autouse = true,
  directories = { vim.fn.stdpath("config") .. "/skeletons" },
  patterns = {},
  wildcards = {
    expand = true,
    lookup = {
      -- File related
      ["filename"]    = function() return vim.fn.expand("%:t:r") end,
      ["fileabspath"] = function() return vim.fn.expand("%:p") end,
      ["filerelpath"] = function() return vim.fn.expand("%:p:~") end,
      ["fileext"]     = function() return vim.fn.expand("%:e") end,
      ["filetype"]    = function() return vim.bo.filetype end,
      -- Date and time related
      ["date"]  = function() return os.date("%Y%m%d", os.time()) end,
      ["year"]  = function() return os.date("%Y", os.time()) end,
      ["month"] = function() return os.date("%m", os.time()) end,
      ["day"]   = function() return os.date("%d", os.time()) end,
      ["time"]  = function() return os.date("%T", os.time()) end,
      -- System related
      ["host"] = utils.capture("hostname", false),
      ["user"] = os.getenv("USER"),
      -- Github related
      ["gh-email"] = utils.capture("git config user.email", false),
      ["gh-user"]  = utils.capture("git config user.name", false),
    },
  },
  advanced = {
    ignored = {},
    ignore_os_files = true,
  }
}
```

## Roadmap

`esqueleto.nvim` is in its infancy (expect breaking changes from time to time).
I intend on extending this plugin with some functionality I would like for a template
manager. At some point `esqueleto.nvim` should have the following (ordered by priority):

- [ ] Template creation interface
- [x] Wildcard expansion
- [x] User customizable wildcard look-up tables
- [x] ~Project specific templates~ Support for multiple template directory
- [ ] Template insertion prompt using [Telescope](https://github.com/nvim-telescope/telescope.nvim)
- [ ] User customizable insertion prompt

## Contributing

Pull requests are welcomed for improvement of tool and community templates.
Please contribute using [GitHub Flow](https://guides.github.com/introduction/flow/).
Create a branch, add commits, and
[open a pull request](https://github.com/cvigilv/esqueleto.nvim/compare/).

Please [open an issue](https://github.com/cvigilv/esqueleto.nvim/issues/new) for
support.
