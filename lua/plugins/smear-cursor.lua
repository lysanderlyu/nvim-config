return {
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      smear_ms = 50,
      smear_length = 20,
      cursor_color = nil,
      keep_smear_on_idle = false,
      hide_builtin_cursor = true,
      
      -- Disable smear while typing
      enabled_in_insert_mode = false,
      enabled_in_terminal_mode = false, -- Also usually better to off in terminal

      smear_between_buffers = true,
      smear_between_neighbor_lines = true,
      scroll_buffer_space = true,
      legacy_computing_symbols_support = false,
    },
  }
}
