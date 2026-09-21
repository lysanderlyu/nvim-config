return {
  {
    "hat0uma/csvview.nvim",
    ft = { "csv", "tsv" },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle", "CsvViewInfo" },
    keys = {
      { "<leader>cv", "<cmd>CsvViewToggle<cr>", desc = "Toggle CSV view" },
      { "<leader>ci", "<cmd>CsvViewInfo<cr>", desc = "CSV view info" },
    },
    opts = {
      parser = {
        -- Lines starting with these are rendered as-is, not tabularized.
        comments = { "#", "//" },
      },
      -- Delimiter, header detection, sticky header and "highlight" display mode
      -- all keep the plugin defaults; `:CsvViewEnable <option>=<value>` overrides
      -- them per buffer.
      keymaps = {
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<Enter>", mode = { "n", "v" } },
        jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
      },
    },
    config = function(_, opts)
      require("csvview").setup(opts)

      -- csvview never attaches on its own, and lazy loads it on the FileType
      -- event — so enable the buffer that triggered the load here, and rely on
      -- the autocmd for every csv/tsv buffer opened afterwards.
      local csv_fts = { csv = true, tsv = true }
      if csv_fts[vim.bo.filetype] then
        vim.cmd("CsvViewEnable")
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("CsvViewAutoEnable", {}),
        pattern = { "csv", "tsv" },
        callback = function()
          vim.cmd("CsvViewEnable")
        end,
      })
    end,
  },
}
