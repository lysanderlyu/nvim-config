local M = {}

-----------------------------------------------------------
-- Enable diff for exactly two windows
-----------------------------------------------------------
function M.DiffTwoWindows()
  local wins = vim.api.nvim_tabpage_list_wins(0) -- only current tab
  local normal_wins = {}

  -- filter normal windows (exclude floating / plugin)
  for _, win in ipairs(wins) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative == "" then
      table.insert(normal_wins, win)
    end
  end

  if #normal_wins ~= 2 then
    print("Exactly two NORMAL windows must be open in this tab!")
    return
  end

  for _, win in ipairs(normal_wins) do
    vim.api.nvim_win_call(win, function()
      vim.cmd("diffthis")
    end)
  end

  print("Diff mode enabled for this tab ✔")
end

-----------------------------------------------------------
-- Cancel diff mode for all windows
-----------------------------------------------------------
function M.CancelDiff()
  vim.cmd("diffoff!")
end

-----------------------------------------------------------
-- Keymaps
-----------------------------------------------------------
vim.keymap.set("n", "<leader>;d", M.DiffTwoWindows, { desc = "Diff the two windows" })
vim.keymap.set("n", "<leader>;D", M.CancelDiff, { desc = "Cancel diff mode" })

return M
