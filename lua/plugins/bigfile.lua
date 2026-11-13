-- Features disabled in files larger than `filesize` MiB. Toggle with
-- <leader>uB / :BigfileToggle: it applies to the current buffer and to buffers
-- opened afterwards. Other already-open buffers are left untouched.
local features = {
  "illuminate",
  "indent_blankline",
  "lsp",
  "matchparen",
  "syntax",
  -- no-op on nvim-treesitter main: bigfile's treesitter hook needs the old
  -- `nvim-treesitter.configs` module from the master branch. The toggle below
  -- stops/starts treesitter itself.
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
    local uv = vim.uv or vim.loop
    local enabled = true

    local function is_big(buf)
      local ok, stat = pcall(uv.fs_stat, vim.api.nvim_buf_get_name(buf))
      return ok and stat and math.floor(0.5 + stat.size / (1024 * 1024)) >= opts.filesize
    end

    local function is_limited(buf)
      return not vim.b[buf].bigfile_off
        and (vim.b[buf].bigfile_detected == 1 or vim.b[buf].bigfile_manual == true)
    end

    local function apply(buf)
      -- Stop treesitter first: destroying the highlighter re-runs the
      -- `syntaxset` FileType handlers, which would set 'syntax' back to the
      -- filetype after bigfile turned it off.
      pcall(vim.treesitter.stop, buf)
      -- bigfile's lsp hook only blocks future attaches; drop current ones too.
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
        pcall(vim.lsp.buf_detach_client, buf, client.id)
      end
      local feat = require("bigfile.features")
      vim.api.nvim_buf_call(buf, function()
        for _, name in ipairs(opts.features) do
          local f = feat.get_feature(name)
          if f and f.disable then
            pcall(f.disable, buf)
          end
        end
      end)
      vim.b[buf].bigfile_manual = true
    end

    local function undo(buf)
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      vim.b[buf].bigfile_manual = nil
      -- Remove the buffer-local LspAttach blocker bigfile installed; there are
      -- no user buffer-local LspAttach autocmds in this config.
      pcall(vim.api.nvim_clear_autocmds, { event = "LspAttach", buffer = buf })
      vim.api.nvim_buf_call(buf, function()
        -- bigfile ran `syntax clear` and set 'syntax' to OFF.
        if vim.bo.syntax:upper() == "OFF" and vim.bo.filetype ~= "" then
          vim.bo.syntax = vim.bo.filetype
        end
        -- Let ftplugin, treesitter and lspconfig handlers run again.
        vim.api.nvim_exec_autocmds("FileType", { buffer = buf, modeline = false })
      end)
      if vim.fn.exists(":DoMatchParen") == 2 then
        pcall(vim.cmd, "DoMatchParen")
      end
    end

    local function apply_global()
      -- setup() registers its BufReadPre autocmd in the "bigfile" augroup;
      -- clearing that augroup is the only way to unregister it.
      vim.api.nvim_create_augroup("bigfile", {})
      vim.api.nvim_clear_autocmds({ group = "bigfile" })
      vim.api.nvim_create_augroup("bigfile_ts", {})
      vim.api.nvim_clear_autocmds({ group = "bigfile_ts" })
      if not enabled then
        return
      end
      require("bigfile").setup(opts)
      -- bigfile's "treesitter" feature is a no-op on nvim-treesitter main, so
      -- stop the highlighter ourselves once the file has been read.
      vim.api.nvim_create_autocmd("BufReadPost", {
        group = "bigfile_ts",
        callback = function(ev)
          if vim.b[ev.buf].bigfile_detected == 1 and not vim.b[ev.buf].bigfile_off then
            pcall(vim.treesitter.stop, ev.buf)
          end
        end,
      })
    end

    apply_global()

    local function set(state)
      enabled = state
      apply_global()

      local buf = vim.api.nvim_get_current_buf()
      if enabled then
        if is_big(buf) and not is_limited(buf) then
          apply(buf)
        end
        vim.b[buf].bigfile_off = nil
      else
        if is_limited(buf) then
          undo(buf)
        end
        vim.b[buf].bigfile_off = true
      end

      vim.notify(
        "bigfile " .. (enabled and "enabled" or "disabled")
          .. " (this and new buffers)",
        vim.log.levels.INFO
      )
    end

    vim.keymap.set("n", "<leader>uB", function()
      set(not enabled)
    end, { desc = "Toggle bigfile" })

    vim.api.nvim_create_user_command("BigfileToggle", function()
      set(not enabled)
    end, { desc = "Toggle bigfile" })
  end,
}
