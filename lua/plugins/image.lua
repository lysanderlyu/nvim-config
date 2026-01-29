local function is_image_terminal()
  local term = vim.env.TERM or ""

  -- Wezterm
  if term:find("wezterm") or vim.env.WEZTERM_WINDOW_ID then
    return true
  end

  -- Kitty
  if term:find("kitty") or vim.env.KITTY_WINDOW_ID then
    return true
  end

  -- Ghostty
  if term:find("ghostty") or vim.env.GHOSTTY_RESOURCES_DIR then
    return true
  end

  return false
end

return {
  {
    "3rd/image.nvim",
    build = false, 

    cond = function()
      return is_image_terminal()
    end,

    config = function()
      require("image").setup({
        backend = "kitty", -- Ghostty supports this natively
        processor = "magick_cli", -- Using CLI bypasses the 'magick' rock error
        integrations = {
          markdown = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
            only_render_image_at_cursor_mode = "popup",
            floating_windows = false,
            filetypes = { "markdown", "vimwiki" },
          },
          neorg = {
            enabled = true,
            filetypes = { "norg" },
          },
          typst = {
            enabled = true,
            filetypes = { "typst" },
          },
          html = { enabled = false },
          css = { enabled = false },
        },
        max_width = nil,
        max_height = nil,
        max_width_window_percentage = nil,
        max_height_window_percentage = 50,
        scale_factor = 1.0,
        window_overlap_clear_enabled = false,
        window_overlap_clear_ft_ignore = { 
            "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" 
        },
        editor_only_render_when_focused = false,
        tmux_show_only_in_active_window = false,
        hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
      })
    end,
  },
}
