# esqueleto.nvim

Reduce your boilerplate code the lazy-bones way.

## What is `esqueleto`?

<p align="center">
  <img width="66%" src="https://github.com/cvigilv/esqueleto.nvim/assets/30091515/f3b783f2-2da8-49ae-9ac1-96141bb0b00b">  
</p>

`esqueleto.nvim` is a lua-based plugin that intends to make the use of templates
(or as the Neo/Vim community calls, "skeletons") as easy and straightforward as possible.
The plugin provides the following functionality:

- Template insertion triggered by file type or file name matching.
- Multiple template directories support.
- Template insertion prompt.
- Template creation and modification.
- Wild-card expansion with user-defined and lua-function wild-card support.

## Installation
`esqueleto.nvim` requires the following:

- Neovim 0.8+

Install `esqueleto.nvim` with your preferred package manager:

<details open>
  <summary>lazy.nvim</summary>

```lua
{
  'cvigilv/esqueleto.nvim',
  opts = {},
}
```

</details>

<details>
  <summary>Packer</summary>

```lua
require("packer").startup(function()
  use({
    "cvigilv/esqueleto.nvim",
    config = function()
      require("esqueleto").setup()
    end,
  })
end)
```

</details>

<details>
  <summary>Paq</summary>

```lua
require("paq")({
  { "cvigilv/esqueleto.nvim" },
})
```

</details>

<details>
  <summary>vim-plug</summary>

```vim
Plug 'cvigilv/esqueleto.nvim'
```

</details>

<details>
  <summary>dein</summary>

```vim
call dein#add('cvigilv/esqueleto.nvim')
```

</details>

<details>
  <summary>Pathogen</summary>

```sh
git clone --depth=1 https://github.com/cvigilv/esqueleto.nvim.git ~/.vim/bundle/
```

</details>

<details>
  <summary>Neovim native package</summary>

```sh
git clone --depth=1 https://github.com/cvigilv/esqueleto.nvim.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/pack/esqueleto/start/esqueleto.nvim
```

</details>

> [!NOTE]
> To make use of the latest version of the plug-in you must configure your favorite package
> manager to point to the `develop` branch. But beware, you must expect new functionality, bugs
> and breaking changes from time to time.


## Usage & configuration
### Quick start
`esqueleto.nvim` uses the philosophy of `ftplugin` for organizing templates, that is, inside
the template directory one must organize its templates making reference to its (i) `filetype`
or (ii) file name. As an example, let's assume you have the following structure in you
`~/.config/nvim` directory:

```
nvim
├── init.lua
└── skeletons
    ├── LICENSE
    │   └── MIT
    └── python
        ├── default.py
        └── cli.py
```

Here, we have a single skeleton directory and two possible triggers for template insertion:
`python` files and files named `LICENSE`.

To configure and use `esqueleto.nvim`, we need to tell `esqueleto` that we want to trigger
the insertion for either of this two cases. For that, we add the following to your `init.lua`:

```lua
require("esqueleto").setup(
  {
    patterns = { "LICENSE", "python" },
  }
)
```

With this configuration, one will be prompted with the template insertion whenever an empty
(i) `python` file type or (ii) file named `LICENSE` are create. This configuration will
replicate the behavior seen in the video introduction.

### Defaults
The default options of `esqueleto` are the following:

```lua
{
  -- Standard options
  directories = { vim.fn.stdpath("config") .. "/skeletons" }, -- template directories
  patterns = { }, -- trigger patterns for file creation, file name trigger has priority
  autouse = true, -- whether to auto-use a template if it's the only one for a pattern

  -- Wild-card options
  wildcards = {  
    expand = true, -- whether to expand wild-cards
    lookup = { -- wild-cards look-up table
      -- File-specific
      ["filename"] = function() return vim.fn.expand("%:t:r") end,
      ["fileabspath"] = function() return vim.fn.expand("%:p") end,
      ["filerelpath"] = function() return vim.fn.expand("%:p:~") end,
      ["fileext"] = function() return vim.fn.expand("%:e") end,
      ["filetype"] = function() return vim.bo.filetype end,

      -- Datetime-specific
      ["date"] = function() return os.date("%Y%m%d", os.time()) end,
      ["year"] = function() return os.date("%Y", os.time()) end,
      ["month"] = function() return os.date("%m", os.time()) end,
      ["day"] = function() return os.date("%d", os.time()) end,
      ["time"] = function() return os.date("%T", os.time()) end,

      -- System-specific
      ["host"] = utils.capture("hostname", false),
      ["user"] = os.getenv("USER"),

      -- Github-specific
      ["gh-email"] = utils.capture("git config user.email", false),
      ["gh-user"] = utils.capture("git config user.name", false),
    },
  },

  -- Advanced options
  advanced = {
    ignored = {}, -- List of glob patterns or function that determines if a file is ignored
    ignore_os_files = true, -- whether to ignore OS files (e.g. .DS_Store)
  }
}
```

For more information regarding `esqueleto.nvim` options, refer to docs (`:h esqueleto`).


### Triggers
As previously showcased, `esqueleto.nvim` has two types of triggers: (i) file type and (ii) 
file name triggers. This correspond to the backbone of `esqueleto`, therefore is essential to
correctly understand how the plugin works for proper creation and organization of templates.

`esqueleto` will **prioritize file name over file type templates**, because the first are more
specific than the later. This means that, for example, if one has a named `python` template,
`script.py`, and a set of `python` templates, `esqueleto` will work as follows:

- If file created is named `script.py`, only the `script.py` template will be prompted for
  insertion (*file name trigger*).
- If file created is named `other.py`, all the `python` file type templates will be prompted
  for insertion (*file type trigger*).

This is the intended behavior for `esqueleto`, since one can have, for example, a list of
templates that match all `python` files and link some of this to trigger exclusively when a
file with a specific name is found.

So, from the quickstart example, let's create a new trigger for files named `cli.py`. First,
we will add the trigger to the configuration table:

```lua
require("esqueleto").setup(
  {
    patterns = { "LICENSE", "python", "cli.py" },
  }
)
```

Then, instead of creating a new file, we will create a softlink to the template we already 
have in the `python` directory. From this, we should obtain the following structure:

```
skeletons
├── LICENSE
│   └── MIT
├── python
│   ├── default.py
│   └── cli.py
└── cli.py
    └── template -> ../python/cli.py
```

and now we will trigger template insertion for empty (i) `python` type, (ii) `LICENSE` and
(iii) `cli.py` named files:

<p align="center">
  <img width="66%" src="https://github.com/cvigilv/esqueleto.nvim/assets/30091515/2bc174ca-7a76-4776-8d51-2fd1941091a1">  
</p>

Finally, the command `EsqueletoNew` provides of a user-friendly way for creating new
templates.

### Wild-cards
`esqueleto.nvim` supports wild-card expansion for dynamically filling templates with relevant
information. The current format for wild-cards is the following:

```
${wildcard-identifier}
```

This wild-cards can be defined by the user under the `lookup` table found in the `wildcards`
section of the [configuration table](#defaults). This wild-cards can either be (i) static values, e.g.
strings, numbers, etc., or (ii) functions. Additionally, a special type of wild-cards are
Lua-based function calls, which have the following structure:

```
${lua:function call}
```

`esqueleto` comes with a series of ready-to-use wildcards:

- _File related_
  - `filename`, the current file name
  - `fileabspath`, the current file absolute path
  - `filerelpath`, the current file relative path to `$HOME`
  - `fileext`, the current file extension
  - `filetype`, the current file type

- _Date and time related_
  - `date`, current date in YYYYMMDD format
  - `year`, current year
  - `month`, current month
  - `day`, current day
  - `time`, current time in HH:MM:SS format

- _System related_
  - `host`, current host name
  - `user`, current user name
- Github related
  - `gh-email`, email of GitHub user
  - `gh-user`, name of Github user

Additionally, a special wild-card exists for cursor placement (denoted with `${cursor}`),
which moves the cursor to the last instance of this wildcard once the template is written in
the current buffer.
> [!WARNING]
> *DO NOT OVERWRITE THIS WILDCARD*! This wildcard is protected, therefore replacing it in the
> wildcards look-up table will produce unexpected behaviors.

---

## Roadmap

`esqueleto.nvim` is in its infancy (expect breaking changes from time to time).
I intend on extending this plugin with some functionality I would like for a template
manager.

For version 1.0 (currently in development), the following should be implemented:
- [x] ~Project specific templates~ Multiple template directories support
- [x] Wild-cards
  - [x] Format spec
  - [x] Expansion rules
  - [x] User defined wild-cards
- [x] Template creation interface

For version 2.0, the following should be implemented:
- General UI/UX improvements
- [Telescope](https://github.com/nvim-telescope/telescope.nvim)-based template selector
- Floating window template selector
- User customizable prompt UI
- User customizable insertion rules

---

## Similar plugins
`esqueleto.nvim` is just on of the template insertion plugins currently available for
Neovim. Here are some other proyects that are similar in nature:

- [spooky.nvim](https://github.com/Futarimiti/spooky.nvim)
- [template.nvim](https://github.com/nvimdev/template.nvim)
- [new-file-template.nvim](https://github.com/otavioschwanck/new-file-template.nvim)
- [skel-nvim](https://github.com/motosir/skel-nvim)

---

## Contributing

Pull requests are welcomed for improvement of tool and community templates. Please contribute
using [GitHub Flow](https://guides.github.com/introduction/flow/). Create a branch, add
commits, and [open a pull request](https://github.com/cvigilv/esqueleto.nvim/compare/).

Please [open an issue](https://github.com/cvigilv/esqueleto.nvim/issues/new) for support.
