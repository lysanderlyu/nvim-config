return {
  {
    "junegunn/fzf",
    build = function()
      vim.fn["fzf#install"]()
    end,
  },
  {
    "junegunn/fzf.vim",
    config = function()
      local opts = { noremap = true, silent = true }

      -- Keymap: search clipboard (+ register)
      vim.keymap.set("n", "<leader>sS", function()
        local yank = vim.fn.getreg('+')
        if yank == "" then
          print("No yanked text")
          return
        end
        -- Trim trailing newline characters (\n or \r)
        yank = yank:gsub("[\r\n]+$", "")

        local query = '"' .. yank .. '"'
        -- vim.cmd("Rg " .. yank)
        vim.fn["fzf#vim#grep"](
          "rg --column --line-number --no-heading --color=always --smart-case -- " .. query,
          vim.fn["fzf#vim#with_preview"]({
            options = {
              "--layout=reverse",   -- input at top
              "--info=default",   -- keeps info line fixed at bottom
              "--prompt=Search> "
            },
            preview_window = "right:50%"  -- keep preview on right
          }),
          0
        )
      end, opts)

      -- Keymap: search default (" register)
      vim.keymap.set("n", "<leader>ss", function()
        local yank = vim.fn.getreg('"')
        if yank == "" then
          print("No yanked text")
          return
        end
        local query = '"' .. yank .. '"'
        -- vim.cmd("Rg " .. yank)
        vim.fn["fzf#vim#grep"](
          "rg --column --line-number --no-heading --color=always --smart-case -- " .. query,
          vim.fn["fzf#vim#with_preview"]({
            options = {
              "--layout=reverse",   -- input at top
              "--info=default",   -- keeps info line fixed at bottom
              "--prompt=Search> "
            },
            preview_window = "right:50%"  -- keep preview on right
          }),
          0
        )
      end, opts)
    end,
  },
}
