return {
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      stiffness = 0.3,
      trailing_stiffness = 0.5,
      matrix_pixel_threshold = 0.3,
      damping = 0.95,
      damping_insert_mode = 0.95,
      distance_stop_animating = 0.5,

      particle_spread = 1,
      particles_per_second = 500,
      particles_per_length = 50,
      particle_max_lifetime = 800,
      particle_max_initial_velocity = 20,
      particle_velocity_from_cursor = 0.5,
      particle_damping = 0.15,
      particle_gravity = -50,
      min_distance_emit_particles = 0,

      time_interval = 4,
      smear_ms = 50,
      smear_length = 20,
      cursor_color = "#C6C8C5",
      keep_smear_on_idle = false,
      hide_builtin_cursor = true,

      -- Disable smear while typing
      smear_insert_mode = false,
      enabled_in_insert_mode = false,
      enabled_in_terminal_mode = false,
      -- Don't replace the Noice cmdline cursor with a block smear;
      -- leave the real cursor so guicursor `c:ver25` can show an insert bar.
      smear_to_cmd = false,

      smear_between_buffers = true,
      smear_between_neighbor_lines = true,
      scroll_buffer_space = true,
      legacy_computing_symbols_support = false,
    },
    config = function(_, opts)
      require("smear_cursor").setup(opts)

      -- While animating, smear-cursor hides the real cursor by appending
      -- `a:SmearCursorHide` to guicursor, and only restores it when an
      -- animation finishes. Pressing `:` right after a visual selection
      -- changes mode V -> n -> c before the smear settles, so the real cursor
      -- stays hidden for the whole command line; with smear_to_cmd = false
      -- nothing restores it, and Noice's cmdline popup has no cursor at all.
      -- Jumping to the cursor position calls smear's own unhide routine and
      -- clears that state before the popup draws.
      vim.api.nvim_create_autocmd("CmdlineEnter", {
        callback = function()
          local ok, animation = pcall(require, "smear_cursor.animation")
          if ok and type(animation.jump) == "function" then
            pcall(animation.jump, vim.fn.screenrow(), vim.fn.screencol())
          end
        end,
      })
    end,
  }
}
