local augroup = vim.api.nvim_create_augroup("NeoTreeFix", { clear = true })

-- 📌 Переключение на следующий буфер при удалении текущего
vim.api.nvim_create_autocmd("BufDelete", {
  group = augroup,
  callback = function()
    vim.schedule(function()
      local bufs = vim.fn.getbufinfo({ buflisted = 1 })
      if #bufs > 0 then
        vim.cmd("bnext")
      end
    end)
  end,
})

-- 📌 Вставка временного scratch-буфера, если осталась одна Neo-tree
vim.api.nvim_create_autocmd("WinEnter", {
  group = augroup,
  callback = function()
    vim.schedule(function()
      local wins = vim.api.nvim_tabpage_list_wins(0)
      if #wins == 1 then
        local buf = vim.api.nvim_win_get_buf(wins[1])
        local ft = vim.api.nvim_buf_get_option(buf, "filetype")
        if ft == "neo-tree" then
          -- Запоминаем Neo-tree окно
          local neo_win = wins[1]

          -- Открываем vsplit и создаём временный буфер
          vim.cmd("vsplit")
          local scratch_win = vim.api.nvim_get_current_win()
          local scratch_buf = vim.api.nvim_create_buf(false, true) -- scratch = nofile, hidden
          vim.api.nvim_buf_set_option(scratch_buf, "buftype", "nofile")
          vim.api.nvim_buf_set_option(scratch_buf, "bufhidden", "wipe")
          vim.api.nvim_buf_set_option(scratch_buf, "swapfile", false)
          vim.api.nvim_buf_set_name(scratch_buf, "[scratch-keep-layout]")
          vim.api.nvim_win_set_buf(scratch_win, scratch_buf)

          -- Принудительно вернуть ширину Neo-tree
          vim.api.nvim_win_set_width(neo_win, 40)

          -- 📌 Удалим этот буфер при первом открытии нормального файла
          vim.api.nvim_create_autocmd("BufEnter", {
            once = true,
            group = augroup,
            callback = function(event)
              local newft = vim.api.nvim_buf_get_option(event.buf, "filetype")
              if newft ~= "neo-tree" and newft ~= "" then
                -- Закрываем окно scratch-буфера, если всё ок
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  local b = vim.api.nvim_win_get_buf(win)
                  if vim.api.nvim_buf_get_name(b) == "[scratch-keep-layout]" then
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

