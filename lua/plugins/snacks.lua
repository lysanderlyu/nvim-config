local function is_graphical_terminal()
  local term = vim.env.TERM or ""

  -- Kitty
  if term:find("kitty") or vim.env.KITTY_WINDOW_ID then
    return true
  end

  -- Ghostty
  if term:find("ghostty") or vim.env.GHOSTTY_RESOURCES_DIR then
    return true
  end

  -- WezTerm (WSL-safe)
  if term == "wezterm"
     or vim.env.TERM_PROGRAM == "WezTerm"
     or vim.env.WEZTERM_PANE
  then
    return true
  end

  return false
end

-- Pathspecs for git-log preview: prefer item.files (renames from git_log_file),
-- then opts.pathspec / cmd_args after `--` (nvim-tree gd scopes a file/dir).
local function git_log_pathspec(ctx)
  local function clean(list)
    local out = {}
    for _, p in ipairs(list or {}) do
      if type(p) == "string" and p ~= "" then
        out[#out + 1] = p
      end
    end
    return out
  end

  local from_item = ctx.item.files or ctx.item.file
  if type(from_item) ~= "table" then
    from_item = from_item and { from_item } or {}
  end
  from_item = clean(from_item)
  if #from_item > 0 then
    return from_item
  end

  local opts = ctx.picker.opts or {}
  if opts.pathspec then
    local ps = opts.pathspec
    return clean(type(ps) == "table" and ps or { ps })
  end

  local out, after = {}, false
  for _, arg in ipairs(opts.cmd_args or {}) do
    if after then
      out[#out + 1] = arg
    elseif arg == "--" then
      after = true
    end
  end
  return clean(out)
end

-- Git-log preview: full message always; full `git show` when ≤300 lines changed,
-- otherwise `--stat`. Pathspec keeps previews file/dir-scoped (like <leader>gD).
local function git_log_stat_preview(ctx)
  local commit = ctx.item.commit
  if not commit then
    return
  end

  local cwd = ctx.item.cwd or ctx.picker.opts.cwd
  local pathspec = git_log_pathspec(ctx)

  -- numstat: "<added>\t<deleted>\t<path>" — sum added+deleted for line budget
  local count_cmd = { "git", "--no-pager", "diff-tree", "--no-commit-id", "--numstat", "-r", commit }
  if #pathspec > 0 then
    count_cmd[#count_cmd + 1] = "--"
    vim.list_extend(count_cmd, pathspec)
  end

  local line_count = math.huge
  local ok, result = pcall(function()
    return vim.system(count_cmd, { cwd = cwd, text = true }):wait()
  end)
  if ok and result and result.code == 0 then
    line_count = 0
    for line in vim.gsplit(result.stdout or "", "\n", { trimempty = true }) do
      local added, deleted = line:match("^(%S+)\t(%S+)\t")
      if added and deleted then
        -- binary files show "-" for both
        local a = tonumber(added) or 0
        local d = tonumber(deleted) or 0
        line_count = line_count + a + d
      end
    end
  end

  -- medium = full commit message body; never truncate the message for large diffs
  local cmd = { "git", "--no-pager", "show", "--format=medium" }
  if line_count > 300 then
    cmd[#cmd + 1] = "--stat"
  end
  cmd[#cmd + 1] = commit
  if #pathspec > 0 then
    cmd[#cmd + 1] = "--"
    vim.list_extend(cmd, pathspec)
  end

  Snacks.picker.preview.cmd(cmd, ctx, { ft = "git" })
end

-- Scroll the picker preview a fixed number of lines instead of half a page
local function preview_scroll_lines(count, up)
  return function(picker)
    local win = picker.preview.win
    if not win:valid() then
      return
    end
    vim.api.nvim_win_call(win.win, function()
      vim.cmd(("normal! %d%s"):format(count, Snacks.util.keycode(up and "<c-y>" or "<c-e>")))
    end)
  end
end

local git_log_light_preview = {
  preview = git_log_stat_preview,
  -- fancy is fine for small full diffs / --stat; huge patches are avoided above
  previewers = { diff = { style = "syntax" } },
}

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = false },
      dashboard = { enabled = false },
      explorer = { enabled = false },
      indent = { enabled = false },
      input = { enabled = true },
      notifier = {
        enabled = true,
        timeout = 3000,
      },
      picker = {
        enabled = true,
        -- <c-j>/<c-k> scroll the preview in every picker; list nav stays on <c-n>/<c-p>
        actions = {
          preview_lines_down = preview_scroll_lines(1, false),
          preview_lines_up = preview_scroll_lines(1, true),
        },
        win = {
          input = {
            keys = {
              ["<c-j>"] = { "preview_lines_down", mode = { "i", "n" } },
              ["<c-k>"] = { "preview_lines_up", mode = { "i", "n" } },
            },
          },
          list = {
            keys = {
              ["<c-j>"] = "preview_lines_down",
              ["<c-k>"] = "preview_lines_up",
            },
          },
        },
        layouts = {
          default = {
            layout = {
              box = "horizontal",
              width = 0.95,
              height = 0.95,
              {
                box = "vertical",
                border = true,
                title = "{title} {live} {flags}",
                width = 0.45,
                { win = "input", height = 1, border = "bottom" },
                { win = "list", border = "none" },
              },
              { win = "preview", title = "{preview}", border = true, width = 0.55 },
            },
          },
          vertical = {
            layout = { width = 0.95, height = 0.95 },
          },
        },
        sources = {
          -- Full git show + fancy diff freezes the UI on large commits
          git_log = vim.deepcopy(git_log_light_preview),
          git_log_file = vim.deepcopy(git_log_light_preview),
          git_log_line = vim.deepcopy(git_log_light_preview),
        },
      },
      quickfile = { enabled = true },
      scope = { 
          enabled = true,
      },
      -- image = is_graphical_terminal() and {
      image = {
        enabled = true,
        formats = {
          "png",
          "jpg",
          "jpeg",
          "gif",
          "bmp",
          "webp",
          "tiff",
          "heic",
          "avif",
          "mp4",
          "mov",
          "avi",
          "mkv",
          "webm",
          "pdf",
          "icns",
        },
        doc = {
          max_width = 120,
          max_height = 40,
        },
      } or {
        enabled = false,
      },
      scroll = { 
          enabled = true,
          -- Main scroll animation
          animate = {
            -- Smaller step = smaller increments = smoother
            duration = { step = 8, total = 300 },
            -- Better easing
            easing = "linear",
          },
          -- When holding the key (repeat animation)
          animate_repeat = {
            delay = 100,
            duration = { step = 4, total = 150 },
            easing = "linear",
          },
          filter = function(buf)
            return vim.g.snacks_scroll ~= false
              and vim.b[buf].snacks_scroll ~= false
              and vim.bo[buf].buftype ~= "terminal"
          end,
      },
      statuscolumn = { enabled = true },
      words = {
        enabled = true,
        -- clangd rejects non-file URIs (fugitive://, etc.)
        filter = function(buf)
          local name = vim.api.nvim_buf_get_name(buf)
          return vim.g.snacks_words ~= false
            and vim.b[buf].snacks_words ~= false
            and not name:match("^%a+://")
        end,
      },
      styles = {
        notification = {
          -- wo = { wrap = true } -- Wrap notifications
        }
      }
    },
    keys = {
      -- Top Pickers & Explorer
      -- { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
      -- { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      -- { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
      { "<leader>E", function() Snacks.explorer() end, desc = "File Explorer" },
      -- find
      { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
      -- git
      { "<leader>gl", function()
        local opts = vim.deepcopy(git_log_light_preview)
        opts.confirm = function(picker, item)
          picker:close()
          local hash = item and (item.oid or item.commit)
          if not hash then
            return
          end
          -- Gtabedit: open commit object with full diff (no :Git job → no hit-enter)
          vim.schedule(function()
            vim.cmd("Gtabedit " .. vim.fn.fnameescape(hash))
          end)
        end
        Snacks.picker.git_log(opts)
      end, desc = "Git Log → Show Diff" },
      { "<leader>gL", function()
        Snacks.picker.git_log_line(vim.deepcopy(git_log_light_preview))
      end, desc = "Git Log Line" },
      -- Grep
      { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },

      -- search
      -- { "<leader>sC", function() Snacks.terminal() end, desc = "System command line" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
      { "<leader>sI", function() Snacks.picker.icons() end, desc = "Icons" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
      { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
      { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
      { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
      { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
      { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
      { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
      { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
      -- Other
      { "<leader>z",  function() Snacks.zen() end, desc = "Toggle Zen Mode" },
      -- { "<leader>Z",  function() Snacks.zen.zoom() end, desc = "Toggle Zoom" },
      -- { "<leader>.",  function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
      -- { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
      { "<leader>n",  function() Snacks.notifier.show_history() end, desc = "Notification History" },
      -- { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
      { "<leader>cr", function() Snacks.rename.rename_file() end, desc = "Rename File" },
      -- { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse", mode = { "n", "v" } },
      -- { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
      { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
      -- { "<c-/>",      function() Snacks.terminal() end, desc = "Toggle Terminal" },
      -- { "<c-_>",      function() Snacks.terminal() end, desc = "which_key_ignore" },
      -- { "]]",         function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
      -- { "[[",         function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end

          -- Override print to use snacks for `:=` command
          if vim.fn.has("nvim-0.11") == 1 then
            vim._print = function(_, ...)
              dd(...)
            end
          else
            vim.print = _G.dd 
          end

          -- Create some toggle mappings
          Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
          Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
          Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
          Snacks.toggle.diagnostics():map("<leader>ud")
          Snacks.toggle.line_number():map("<leader>ul")
          Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
          Snacks.toggle.treesitter():map("<leader>uT")
          Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
          Snacks.toggle.inlay_hints():map("<leader>uh")
          Snacks.toggle.indent():map("<leader>ui")
          Snacks.toggle.dim():map("<leader>uD")

        end,
      })
    end,
  }
}
