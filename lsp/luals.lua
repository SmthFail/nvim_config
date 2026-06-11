local cache_dir = vim.fn.stdpath('cache') .. '/lua-language-server'

vim.fn.mkdir(cache_dir .. '/log', 'p')
vim.fn.mkdir(cache_dir .. '/meta', 'p')

---@type vim.lsp.Config
return {
  cmd = {
    'lua-language-server',
    '--logpath=' .. cache_dir .. '/log',
    '--metapath=' .. cache_dir .. '/meta',
  },

  filetypes = { 'lua' },

  root_markers = {
    '.luarc.json',
    '.luarc.jsonc',
    '.git',
  },

  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      diagnostics = {
        globals = { 'vim' },
      },
      workspace = {
        library = {
          vim.env.VIMRUNTIME,
          vim.fn.stdpath('config'),
        },
      },
      telemetry = {
        enable = false,
      },
    },
  },
}
