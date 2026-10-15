return {
  {
    "stevearc/aerial.nvim",
    branch = "nvim-0.11",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    event = { "BufReadPost", "BufNewFile" },
    ft = "man",
    keys = {
      {
        "<leader>ao",
        function()
          require("aerial").toggle({ focus = false })
        end,
        desc = "Aerial Outline",
      },
    },
    opts = {
      backends = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
      -- One outline per tab; it follows the current window instead of opening again on split.
      attach_mode = "global",
      layout = {
        min_width = 10,
      },
      keymaps = {
        ["q"] = function()
          local aer = require("aerial")
          aer.close()
        end,
      },
      -- Do not skip help, man, or other non-empty buftypes. Aerial's default
      -- "special" setting ignores every buftype except normal, help, and man.
      ignore = {
        buftypes = false,
      },
      open_automatic = function(bufnr)
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return false
        end
        local name = vim.api.nvim_buf_get_name(bufnr)
        if name == "" or vim.fn.isdirectory(name) == 1 then
          return false
        end
        -- A manual close (q or <leader>ao) sets was_closed until the next open.
        -- Without this, entering the file buffer opens the outline again immediately.
        local aer = require("aerial")
        if aer.was_closed() then
          return false
        end
        -- man2 (:Man) and other non-Tree-sitter documents use their own backend.
        local backends = require("aerial.backends")
        for _, name in ipairs(require("aerial.config").backends(bufnr)) do
          if backends.is_supported(bufnr, name) then
            return true
          end
        end
        return false
      end,
      -- Keep a manual open visible even when the buffer has no symbol backend.
      close_automatic_events = {},
      filter_kind = {
        "Class",
        "Constructor",
        "Enum",
        "Function",
        "Interface",
        "Module",
        "Method",
        "Struct",
      },
      -- Markdown-specific config
      markdown = {
        -- show only headings, not lists
        include_headers = true,
        include_lists = false,
      },
    },
    config = function(_, opts)
      local aerial = require("aerial")
      aerial.setup(opts)

      local function is_outline_win(winid)
        local buf = vim.api.nvim_win_get_buf(winid)
        if vim.bo[buf].filetype == "aerial" then
          return true
        end
        local ok, flag = pcall(vim.api.nvim_win_get_var, winid, "is_aerial_win")
        return ok and flag == true
      end

      local function is_file_win(winid)
        if not vim.api.nvim_win_is_valid(winid) or vim.api.nvim_win_get_config(winid).relative ~= "" then
          return false
        end
        if is_outline_win(winid) then
          return false
        end
        local buf = vim.api.nvim_win_get_buf(winid)
        if not vim.api.nvim_buf_is_valid(buf) then
          return false
        end
        -- Any named file keeps the outline, whatever its buftype is.
        local name = vim.api.nvim_buf_get_name(buf)
        return name ~= "" and vim.fn.isdirectory(name) == 0
      end

      local function is_blank_win(winid)
        if is_outline_win(winid) then
          return false
        end
        local buf = vim.api.nvim_win_get_buf(winid)
        return vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) == ""
      end

      -- Tree, terminal, help, and other real windows should keep Neovim open.
      -- A leftover unnamed buffer or the outline should not.
      local function is_keep_win(winid)
        if not vim.api.nvim_win_is_valid(winid) or vim.api.nvim_win_get_config(winid).relative ~= "" then
          return false
        end
        if is_outline_win(winid) or is_blank_win(winid) then
          return false
        end
        return true
      end

      local function close_outline_windows()
        for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.api.nvim_win_is_valid(winid) and is_outline_win(winid) then
            pcall(vim.api.nvim_win_close, winid, false)
          end
        end
      end

      local function tab_has(pred, tab)
        for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tab or 0)) do
          if pred(winid) then
            return true
          end
        end
        return false
      end

      local scheduled = false
      local quit_blocked = false
      local group = vim.api.nvim_create_augroup("AerialCloseWithoutFile", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "BufDelete", "BufWipeout", "WinClosed" }, {
        desc = "Close Aerial when the tab has no file buffer",
        group = group,
        callback = function()
          if scheduled then
            return
          end
          scheduled = true
          -- Wait until buffer delete and Aerial's own window update have finished.
          vim.defer_fn(function()
            scheduled = false
            if tab_has(is_file_win) then
              quit_blocked = false
              return
            end
            if tab_has(is_keep_win) then
              close_outline_windows()
              return
            end
            if quit_blocked then
              return
            end

            local current = vim.api.nvim_get_current_tabpage()
            local elsewhere = false
            for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
              if tab ~= current and (tab_has(is_file_win, tab) or tab_has(is_keep_win, tab)) then
                elsewhere = true
                break
              end
            end

            -- Nothing left but the outline and/or an empty window: leave Neovim.
            -- Another tab still in use: close only this tab.
            local ok = pcall(vim.cmd, elsewhere and "tabclose" or "qa")
            if not ok then
              quit_blocked = true
              close_outline_windows()
            end
          end, 50)
        end,
      })

      local function open_if_supported(bufnr)
        vim.defer_fn(function()
          if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr then
            return
          end
          if vim.bo[bufnr].filetype ~= "man" or require("aerial").is_open() then
            return
          end
          require("aerial.autocommands").on_enter_buffer()
        end, 50)
      end

      -- man2 runs `nvim -c "Man …" -c "wincmd o"`. The man filetype is set after
      -- the first BufEnter, and this plugin is loaded from that FileType event,
      -- so the event itself is already over. wincmd o also runs before a synchronous
      -- open would survive. Open once the startup commands have finished.
      vim.api.nvim_create_autocmd("FileType", {
        desc = "Open Aerial on a man page",
        pattern = "man",
        group = vim.api.nvim_create_augroup("AerialOpenOnMan", { clear = true }),
        callback = function(args)
          open_if_supported(args.buf)
        end,
      })
      if vim.bo.filetype == "man" then
        open_if_supported(vim.api.nvim_get_current_buf())
      end
    end,
  },
}
