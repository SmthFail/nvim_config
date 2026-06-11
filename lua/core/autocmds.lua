-- lsp attach
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('minimal-lsp-attach', { clear = true }),
  callback = function(event)
    local bufnr = event.buf
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then return end

    -- Native Neovim LSP completion instead of blink.cmp.
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
    end

    -- function for custom mapping
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
    end

    -- NOTE: This is defined globally by Neovim itself (see :help lsp-defaults):
    --   gra → code_action
    --   gri → implementation
    --   grn → rename
    --   grr → references
    --   grt → type_definition
    --   gO  → document_symbol

    map('grd', vim.lsp.buf.definition, '[G]oto [D]efinition')
    map('gW', vim.lsp.buf.workspace_symbol, 'Workspace Symbols')

    -- Highlight when cursor holds
    if client:supports_method('textDocument/documentHighlight') then
      local hl_group = vim.api.nvim_create_augroup('lsp-highlight-' .. bufnr, { clear = true })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = bufnr,
        group = hl_group,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = bufnr,
        group = hl_group,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        buffer = bufnr,
        once = true,
        callback = function()
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'lsp-highlight-' .. bufnr }
        end,
      })
    end

    -- Toggle inline hint if available
    if client:supports_method('textDocument/inlayHint') then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }, { bufnr = bufnr })
      end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- fix neotree
local augroup = vim.api.nvim_create_augroup('NeoTreeFix', { clear = true })

-- Switch to the next listed buffer when the current one is deleted.
vim.api.nvim_create_autocmd('BufDelete', {
  group = augroup,
  callback = function()
    vim.schedule(function()
      local bufs = vim.fn.getbufinfo({ buflisted = 1 })
      if #bufs > 0 then
        vim.cmd('bnext')
      end
    end)
  end,
})

-- Insert a temporary scratch buffer if only a Neo-tree window remains.
vim.api.nvim_create_autocmd('WinEnter', {
  group = augroup,
  callback = function()
    vim.schedule(function()
      local wins = vim.api.nvim_tabpage_list_wins(0)
      if #wins == 1 then
        local buf = vim.api.nvim_win_get_buf(wins[1])
        local ft = vim.bo[buf].filetype
        if ft == 'neo-tree' then
          local neo_win = wins[1]

          vim.cmd('vsplit')
          local scratch_win = vim.api.nvim_get_current_win()
          local scratch_buf = vim.api.nvim_create_buf(false, true)
          vim.bo[scratch_buf].buftype = 'nofile'
          vim.bo[scratch_buf].bufhidden = 'wipe'
          vim.bo[scratch_buf].swapfile = false
          vim.api.nvim_buf_set_name(scratch_buf, '[scratch-keep-layout]')
          vim.api.nvim_win_set_buf(scratch_win, scratch_buf)

          vim.api.nvim_win_set_width(neo_win, 40)

          vim.api.nvim_create_autocmd('BufEnter', {
            once = true,
            group = augroup,
            callback = function(event)
              local newft = vim.bo[event.buf].filetype
              if newft ~= 'neo-tree' and newft ~= '' then
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  local b = vim.api.nvim_win_get_buf(win)
                  if vim.api.nvim_buf_get_name(b) == '[scratch-keep-layout]' then
                    vim.api.nvim_win_close(win, true)
                    break
                  end
                end
              end
            end,
          })
        end
      end
    end)
  end,
})
