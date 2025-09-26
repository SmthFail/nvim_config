return {
    vim.lsp.config('ruff', {
        cmd = {'ruff', 'server'},
        init_options = {
        settings = {
          -- Server settings should go here
            filetypes={'python'}
        }
      }
    })
}
