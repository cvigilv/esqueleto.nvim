# esqueleto.nvim

Let a skeleton reduce your boilerplate code.

## What is `esqueleto`?

`esqueleto.nvim` is a minimal plugin that intends to make the use of templates
or "skeletons" as easy and straightfoward as possible. This package adds a prompt
for inserting an specific template when creating a new file that matches an specific
file name or pattern.

## Installation

Install `esqueleto.nvim` with your preferred package manager:

[vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'cvigilv/esqueleto.nvim'
```

[packer](https://github.com/wbthomason/packer.nvim)

```lua
use 'cvigilv/esqueleto.nvim'
```

## Usage & configuration

In order to configure `esqueleto.nvim` and use it, the following should be present in
your `init.lua`:
```lua
require("esqueleto").setup(
    {
      -- Directory where templates are stored
      directory = "~/.config/nvim/skeletons/", --default template directory

      -- Patterns to match when creating new file
      -- Can be either (i) file names or (ii) extension globs.
      -- Exact file name match have priority
      patterns = { "README.md", "*.py" }
    }
)
```
For more information, refer to docs (`:h esqueleto`)

## Support

Please [open an issue](https://github.com/user/repo/issues/new) for
support.

## Contributing

Pull requests are welcomed for improvement of tool and community templates.
Please contribute using [Github Flow]
(https://guides.github.com/introduction/flow/). Create a branch, add
commits, and [open a pull request](https://github.com/user/repo/compare/).
