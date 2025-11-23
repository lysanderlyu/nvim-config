return{
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      smear_ms = 30,          -- speed of smear
      smear_length = 18,      -- how long the tail is
      cursor_color = nil,     -- auto-use highlight color
      keep_smear_on_idle = false,
      hide_builtin_cursor = true,
      -- Smear cursor when switching buffers or windows.
      smear_between_buffers = true,
  
      -- Smear cursor when moving within line or to neighbor lines.
      -- Use `min_horizontal_distance_smear` and `min_vertical_distance_smear` for finer control
      smear_between_neighbor_lines = true,
  
      -- Draw the smear in buffer space instead of screen space when scrolling
      scroll_buffer_space = true,
  
      -- Set to `true` if your font supports legacy computing symbols (block unicode symbols).
      -- Smears and particles will look a lot less blocky.
      legacy_computing_symbols_support = false,
    },
  }
}
