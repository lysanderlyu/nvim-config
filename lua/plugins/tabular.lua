return {
  {
    "godlygeek/tabular",
    cmd = "Tabularize",
    init = function()
      -- Define the helper function here so keymaps can see it
      local function align_by(pattern)
        local count = vim.v.count == 0 and 10 or vim.v.count
        local start_line = vim.fn.line(".")
        local end_line = math.min(start_line + count - 1, vim.fn.line("$"))
        vim.cmd(string.format("%d,%dTabularize /%s/", start_line, end_line, pattern))
      end

      vim.keymap.set("n", "<leader>ac", function() align_by("//") end, { desc = "Align //" })
      vim.keymap.set("n", "<leader>ae", function() align_by("=") end, { desc = "Align =" })
      vim.keymap.set("n", "<leader>a{", function() align_by("{") end, { desc = "Align {" })
    end,
  }
}
