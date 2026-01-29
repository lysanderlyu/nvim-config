return {
  {
    "godlygeek/tabular",
    cmd = "Tabularize",
    config = function()
        -- Align N lines by a given pattern
        local function align_by(pattern)
          local count = vim.v.count
          if count == 0 then count = 10 end  -- default 10 lines
        
          local start_line = vim.fn.line(".")
          local end_line = start_line + count - 1
          local last_line = vim.fn.line("$")
          if end_line > last_line then end_line = last_line end
        
          vim.api.nvim_command(string.format("%d,%dTabularize /%s/", start_line, end_line, pattern))
        end
        
        -- Align // comments
        vim.keymap.set("n", "<leader>ac", function() align_by("//") end,
          { desc = "Align N lines of // comments" })
        
        -- Align by = 
        vim.keymap.set("n", "<leader>ae", function() align_by("=") end,
          { desc = "Align N lines by =" })
        
        -- Align by { 
        vim.keymap.set("n", "<leader>a{", function() align_by("{") end,
          { desc = "Align N lines by {" })
     end,
  }
}
