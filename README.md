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

[vim-plug](https://github.com/junegunn/vim-plug)

```vim
# Stable
Plug 'cvigilv/esqueleto.nvim'

# Development (latest)
Plug 'cvigilv/esqueleto.nvim', { 'branch': 'develop'}
```

[packer](https://github.com/wbthomason/packer.nvim)

```lua
-- Stable
use 'cvigilv/esqueleto.nvim'

-- Development (latest)
use { 'cvigilv/esqueleto.nvim', branch = "develop" }
```

## Usage & configuration

To configure `esqueleto.nvim` and use it, the following should be present in
your `init.lua`:
```lua
require("esqueleto").setup(
    {
      -- Template directories
      directories = {"~/.config/nvim/skeletons/"},

      -- Patterns to match when creating new file
      -- Can be either (i) file names or (ii) file types.
      -- Exact file name match have priority
      patterns = { "README.md", "python" },

      -- whether to auto-use a template if it's the only one for a pattern
      autouse = true,

      advanced = {
        -- List of files glob patterns to ignore
        ignored = {},

        -- Ignore OS files like .DS_Store
        -- Exhaustive list: https://www.toptal.com/developers/gitignore/api/windows,macos,linux
        ignore_os_files = true,
      },
    }
)
```
For more information, refer to docs (`:h esqueleto`). For example skeleton files,
check [the `skeletons` folder](skeletons/).

The default options of `esqueleto` are
~~~lua
    {
      directories = { vim.fn.stdpath("config") .. "/skeletons" },
      patterns = { },
      autouse = true,
      advanced = {
        ignored = {},
        ignore_os_files = true,
      }
    }
~~~

## Roadmap

`esqueleto.nvim` is in its infancy (expect breaking changes from time to time).
I intend on extending this plugin with some functionality I would like for a template
manager. At some point `esqueleto.nvim` should have the following (ordered by priority):

- Template creation interface
- Project specific templates
- Template preview via [Telescope](https://github.com/nvim-telescope/telescope.nvim)
- User customizable prompt and insertion rules

## Contributing

Pull requests are welcomed for improvement of tool and community templates.
Please contribute using [GitHub Flow](https://guides.github.com/introduction/flow/).
Create a branch, add commits, and
[open a pull request](https://github.com/cvigilv/esqueleto.nvim/compare/).

Please [open an issue](https://github.com/cvigilv/esqueleto.nvim/issues/new) for
support.
