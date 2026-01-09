-- line numbers
vim.wo.number = true -- Make line numbers default (default: false)
vim.o.relativenumber = true -- Set relative numbered lines (default: false)

-- mouse
vim.o.mouse = 'a' -- Enable mouse mode (default: '')

-- clipboard
-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)


-- wrap lines
vim.o.wrap = false -- Display lines as one long line (default: true)
vim.o.whichwrap = 'bs<>[]hl' -- Which "horizontal" keys are allowed to travel to prev/next line (default: 'b,s')
vim.o.linebreak = true -- Companion to wrap, don't split words (default: false)

-- line indent
vim.o.autoindent = true -- Copy indent from current line when starting new one (default: true)
vim.o.shiftwidth = 4 -- The number of spaces inserted for each indentation (default: 8)
vim.o.tabstop = 4 -- Insert n spaces for a tab (default: 8)
vim.o.expandtab = true -- Convert tabs to spaces (default: false)
vim.o.smartindent = true -- Make indenting smarter again (default: false)

-- split 
vim.o.splitbelow = true -- Force all horizontal splits to go below current window (default: false)
vim.o.splitright = true -- Force all vertical splits to go to the right of current window (default: false)

-- others
vim.o.softtabstop = 4 -- Number of spaces that a tab counts for while performing editing operations (default: 0)
vim.o.scrolloff = 4 -- Minimal number of screen lines to keep above and below the cursor (default: 0)
vim.o.sidescrolloff = 8 -- Minimal number of screen columns either side of cursor if wrap is `false` (default: 0)
vim.o.showmode = false -- We don't need to see things like -- INSERT -- anymore (default: true)
vim.opt.termguicolors = true -- Set termguicolors to enable highlight groups (default: false)
vim.o.numberwidth = 4 -- Set number column width to 2 {default 4} (default: 4)
vim.o.swapfile = false -- Creates a swapfile (default: true)
vim.o.showtabline = 2 -- Always show tabs (default: 1)

vim.o.inccommand = 'split' -- Preview substituytions live when typing

vim.o.confirm = true -- raise dialog when operation fail due to unsave change in the buffer (like `:q`)


