-- nvim-treesitter main branch, Neovim 0.12+.
-- External requirements for parser installation: tree-sitter CLI 0.26.1+ and a C compiler.
local parsers = {
  'bash',
  'json',
  'jsonc',
  'lua',
  'markdown',
  'markdown_inline',
  'python',
  'rust',
  'toml',
  'vim',
  'vimdoc',
  'yaml',
}

require('nvim-treesitter').setup()
require('nvim-treesitter').install(parsers)

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
  pattern = {
    'bash',
    'sh',
    'json',
    'jsonc',
    'lua',
    'markdown',
    'python',
    'rust',
    'toml',
    'vim',
    'vimdoc',
    'yaml',
  },
  callback = function(event)
    pcall(vim.treesitter.start, event.buf)

    -- Optional treesitter indentation. If it causes weird indenting for some language,
    -- comment the next line out or restrict it by filetype.
    pcall(function()
      vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end)
  end,
})
