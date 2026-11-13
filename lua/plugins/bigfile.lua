-- Features disabled in files larger than `filesize` MiB. Toggle the whole
-- thing with <leader>uB / :BigfileToggle (applies to buffers opened after).
local features = {
  "illuminate",
  "indent_blankline",
  "lsp",
  "matchparen",
  "syntax",
  -- no-op on nvim-treesitter main: bigfile's treesitter hook needs the old
  -- `nvim-treesitter.configs` module from the master branch.
  "treesitter",
  -- "vimopts",
  -- "filetype", -- clearing 'filetype' also stops treesitter (lua ftplugin undo)
}

return {
  "LunarVim/bigfile.nvim",
  -- Tiny plugin, and the toggle must be available before the first big file.
  lazy = false,
  opts = {
    filesize = 10, -- size of the file in MiB, rounded to the closest MiB
    features = features,
  },
  init = function()
    -- The plugin's own after/plugin/bigfile.lua calls setup() with defaults.
    -- Pretending it is loaded makes that auto-setup bail out, so only `opts`
    -- below take effect. (setup() also sets this flag itself.)
    vim.g.loaded_bigfile_plugin = true
  end,
  config = function(_, opts)
    local enabled = true

    local function apply()
      -- setup() registers its BufReadPre autocmd in the "bigfile" augroup;
      -- clearing that augroup is the only way to unregister it.
      vim.api.nvim_create_augroup("bigfile", {})
      vim.api.nvim_clear_autocmds({ group = "bigfile" })
      if enabled then
        require("bigfile").setup(opts)
      end
    end

    local function set(state)
      enabled = state
      apply()
      vim.notify(
        "bigfile " .. (enabled and "enabled" or "disabled") .. " (new buffers only)",
        vim.log.levels.INFO
      )
    end

    apply()

    vim.keymap.set("n", "<leader>uB", function()
      set(not enabled)
    end, { desc = "Toggle bigfile" })

    vim.api.nvim_create_user_command("BigfileToggle", function()
      set(not enabled)
    end, { desc = "Toggle bigfile" })
  end,
}
