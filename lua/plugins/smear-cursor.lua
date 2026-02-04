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

      smear_between_buffers = true,
      smear_between_neighbor_lines = true,
      scroll_buffer_space = true,
      legacy_computing_symbols_support = false,
    },
  }
}
