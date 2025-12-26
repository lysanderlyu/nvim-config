return {
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      local theme = require("configs.lualine.lualine-theme").dim_tabs

      -- Treesitter-based function/class context
      local function current_code_context()
        local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
        if not ok then return "" end

        local node = ts_utils.get_node_at_cursor()
        local context = {}

        while node do
          local type = node:type()
          if type:match("function") or type:match("method") or type:match("class") or type:match("module") then
            local name = ts_utils.get_node_text(node)[1]
            if name and name ~= "" then
              table.insert(context, 1, name)  -- insert at front for top-down order
            end
          end
          node = node:parent()
        end

        if #context > 0 then
          return "⚕️ " .. table.concat(context, " → ")
        else
          return ""
        end
      end

      local function relative_filepath()
        local filepath = vim.api.nvim_buf_get_name(0)  -- full path of current buffer
        if filepath == "" then return "[No Name]" end
      
        local cwd = vim.fn.getcwd()                    -- current working directory
        local relpath = vim.fn.fnamemodify(filepath, ":." )  -- relative path from cwd
      
        -- Append file status
        if vim.bo.modified then
          relpath = relpath .. " [+]"  -- unsaved changes
        elseif vim.bo.readonly then
          relpath = relpath .. " [RO]" -- read-only
        end
      
        return relpath
      end

      require("lualine").setup {
        options = {
          theme = theme,
        },
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
          refresh_time = 16, -- ~60fps
          events = {
            'WinEnter',
            'BufEnter',
            'BufWritePost',
            'SessionLoadPost',
            'FileChangedShellPost',
            'VimResized',
            'Filetype',
            'CursorMoved',
            'CursorMovedI',
            'ModeChanged',
          },
        },
        tabline = {
          lualine_a = { { "tabs", mode = 2 } }, -- tab index + filename
          lualine_x = {},
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_c = {relative_filepath},
          lualine_x = {"os.date('%c')", 'data', 'encoding', 'fileformat', 'filetype'},
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
        winbar = {
          lualine_c = { current_code_context },  -- full code context in winbar
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {'filename'},
          lualine_x = {'location'},
          lualine_y = {},
          lualine_z = {}
        },
      }

      -- Always show the tabline
      vim.o.showtabline = 2
    end,
  },
}

