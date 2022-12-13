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

## Example
 - [![Use the same skeleton in different paths.](https://asciinema.org/a/IHH0te0qHqqffSg55cHDHVWaN.svg)](https://asciinema.org/a/IHH0te0qHqqffSg55cHDHVWaN)

## Roadmap

`esqueleto.nvim` is in its infancy. I intend on extending this plugin with some
functionality I would like for a template manager. At some point `esqueleto.nvim` should 
have the following (ordered by priority):

- Cleaner template storage using Vim `ftplugin` directory style
- Template insertion in empty files
- On-demand template insertion
- Template creation interface
- Handle mmultiple template folders
- Proyect specific templates
- Template preview via [Telescope](https://github.com/nvim-telescope/telescope.nvim)
- User customizable prompt and insertion rules

## Contributing

Pull requests are welcomed for improvement of tool and community templates.
Please contribute using [Github Flow](https://guides.github.com/introduction/flow/).
Create a branch, add commits, and 
[open a pull request](https://github.com/cvigilv/esqueleto.nvim/compare/).

Please [open an issue](https://github.com/cvigilv/esqueleto.nvim/issues/new) for
support.
