require 'core.options'
require 'core.keymaps'

-- Built-in plugin manager, Neovim 0.12+.
-- This replaces lazy.nvim.
vim.pack.add({
  -- UI / theme
  { src = 'https://github.com/shaunsingh/nord.nvim' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
  { src = 'https://github.com/akinsho/bufferline.nvim' },
  { src = 'https://github.com/moll/vim-bbye' },

  -- File tree
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = 'v3.x' },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/MunifTanjim/nui.nvim' },
  { src = 'https://github.com/s1n7ax/nvim-window-picker' },

  -- Treesitter and Markdown rendering
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },
  { src = 'https://github.com/nvim-mini/mini.nvim' },
  { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim' },

  -- Telescope
  { src = 'https://github.com/nvim-telescope/telescope.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope-ui-select.nvim' },
  -- Optional native sorter. After first install run:
  --   cd ~/.local/share/nvim/site/pack/core/opt/telescope-fzf-native.nvim && make
  -- If it is not built, the config below simply skips loading the extension.
  { src = 'https://github.com/nvim-telescope/telescope-fzf-native.nvim' },

  -- Editing helpers
  { src = 'https://github.com/windwp/nvim-autopairs' },
}, { confirm = false })

-- Plugin setup. These files are now plain Lua setup modules, not lazy.nvim specs.
require 'plugins.colortheme'
require 'plugins.neotree'
require 'plugins.bufferline'
require 'plugins.lualine'
require 'plugins.treesitter'
require 'plugins.telescope'
require 'plugins.autopairs'
require 'plugins.render-markdown'

require 'core.autocmds'

vim.diagnostic.config({
  virtual_lines = true,
})


-- enable experimental ui (>0.12)
require('vim._core.ui2').enable({})

-- Common LSP config.
vim.lsp.config('*', {
  capabilities = {
    textDocument = {
      semanticTokens = {
        multilineTokenSupport = true,
      },
    },
  },
  root_markers = { '.git' },
})

vim.lsp.enable({
  'luals',
  'ruff',
  'rust_analyzer',
  'ty',
})
