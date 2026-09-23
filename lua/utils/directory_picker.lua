local M = {}

local NS_TREE = vim.api.nvim_create_namespace("directory_picker.tree")
local NS_CUR = vim.api.nvim_create_namespace("directory_picker.cursor")

---@class directory_picker.Row
---@field path string
---@field name string
---@field dir boolean
---@field last boolean
---@field open boolean
---@field ancestors boolean[]

---@class directory_picker.State
---@field root string
---@field cursor integer
---@field expanded table<string, boolean>
---@field rows directory_picker.Row[]
---@field cache table<string, directory_picker.Row[]>
---@field focus_path? string

local MAX_AUTO_ROWS = 400

---@param dir string
---@return {path:string, name:string, dir:boolean}[]
local function list_children(dir)
  local entries = {}
  local ok, iter = pcall(vim.fs.dir, dir)
  if not ok or type(iter) ~= "function" then
    return entries
  end
  for name, t in iter do
    if name ~= ".git" then
      local path = (dir:gsub("/$", "")) .. "/" .. name
      if t == nil then
        t = vim.fn.isdirectory(path) == 1 and "directory" or "file"
      end
      entries[#entries + 1] = {
        name = name,
        path = path,
        dir = t == "directory",
      }
    end
  end
  table.sort(entries, function(a, b)
    if a.dir ~= b.dir then
      return a.dir
    end
    return a.name:lower() < b.name:lower()
  end)
  return entries
end

---Expand nested dirs so the first preview keeps the real tree, not a flat listing.
---@param state directory_picker.State
local function seed_expanded(state)
  local queue = { state.root }
  local shown = 0
  while #queue > 0 do
    local dir = table.remove(queue, 1)
    local children = state.cache[dir] or list_children(dir)
    state.cache[dir] = children
    if dir ~= state.root and shown + #children > MAX_AUTO_ROWS then
      state.expanded[dir] = nil
    else
      if dir ~= state.root then
        state.expanded[dir] = true
      end
      shown = shown + #children
      for _, child in ipairs(children) do
        if child.dir then
          queue[#queue + 1] = child.path
        end
      end
    end
  end
end

---@param state directory_picker.State
---@return directory_picker.Row[]
local function flatten(state)
  local rows = {}

  local function walk(dir, ancestors)
    local children = state.cache[dir]
    if not children then
      children = list_children(dir)
      state.cache[dir] = children
    end
    for i, child in ipairs(children) do
      local last = i == #children
      local open = child.dir and state.expanded[child.path] == true
      rows[#rows + 1] = {
        path = child.path,
        name = child.name,
        dir = child.dir,
        last = last,
        open = open,
        ancestors = ancestors,
      }
      if open then
        local next_anc = vim.list_extend({}, ancestors)
        next_anc[#next_anc + 1] = last
        walk(child.path, next_anc)
      end
    end
  end

  walk(state.root, {})
  return rows
end

---@param picker snacks.Picker
---@return directory_picker.Row?
local current_row

---@param picker snacks.Picker
---@return directory_picker.State?
local function state_of(picker)
  return picker._dir_preview
end

---@param picker snacks.Picker
---@param root string
---@return directory_picker.State
local function ensure_state(picker, root)
  local state = picker._dir_preview
  if not state or state.root ~= root then
    state = {
      root = root,
      cursor = 1,
      expanded = {},
      rows = {},
      cache = {},
    }
    seed_expanded(state)
    picker._dir_preview = state
  end
  return state
end

---@param win snacks.win
---@param title string
---@param lines string[]
local function file_win_set(win, title, lines)
  if not win:buf_valid() then
    win:scratch()
  end
  pcall(vim.treesitter.stop, win.buf)
  vim.bo[win.buf].modifiable = true
  vim.bo[win.buf].filetype = "snacks_picker_preview"
  vim.bo[win.buf].syntax = ""
  vim.api.nvim_buf_set_lines(win.buf, 0, -1, false, lines)
  vim.bo[win.buf].modifiable = false
  win:set_title(title)
end

local IN_FT_SKIP = {
  ["configure.in"] = true,
  ["MANIFEST.in"] = true,
  ["requirements.in"] = true,
}

---Same filetype as `:edit`, with `.in` treated as kconfig (Config.in / *Config*.in).
---@param path string
---@return string?
local function preview_filetype(path)
  local name = vim.fn.fnamemodify(path, ":t")
  if name:find("%.in$") and not IN_FT_SKIP[name] then
    return "kconfig"
  end
  return vim.filetype.match({ filename = path })
end

---Treesitter + vim syntax, matching a normal `:edit` of `path`.
---@param path string
---@param buf integer
local function apply_open_syntax(path, buf)
  local ft = preview_filetype(path)
  if not ft or ft == "" or ft == "snacks_picker_preview" then
    return
  end
  vim.bo[buf].filetype = ft
  pcall(function()
    require("lazy").load({ plugins = { "nvim-treesitter" } })
  end)
  local ok_lang, lang = pcall(vim.treesitter.language.get_lang, ft)
  local started = false
  if ok_lang and lang then
    local has_queries = #vim.api.nvim_get_runtime_file("queries/" .. lang .. "/highlights.scm", true) > 0
    if has_queries then
      started = pcall(vim.treesitter.start, buf, lang)
    end
  end
  if not started then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("silent! syntax enable")
      vim.bo.syntax = ft
    end)
  end
end

---@param picker snacks.Picker
local function update_file_preview(picker)
  local win = picker.layout and picker.layout.wins and picker.layout.wins.file
  if not win then
    return
  end

  local row = current_row(picker)
  local path = row and not row.dir and row.path or nil
  local key = path or (row and ("dir:" .. row.path) or "empty")
  if win._file_path == key then
    return
  end
  win._file_path = key

  if not path then
    local msg = row and row.dir and ("Directory: " .. row.name) or "Select a file"
    file_win_set(win, " File ", { msg })
    return
  end

  if Snacks.image and Snacks.image.supports_file and Snacks.image.supports_file(path) then
    win:scratch()
    win:set_title(vim.fn.fnamemodify(path, ":t"))
    pcall(Snacks.image.buf.attach, win.buf, { src = path })
    return
  end

  local stat = vim.uv.fs_stat(path)
  if not stat then
    file_win_set(win, " File ", { "File not found" })
    return
  end
  if stat.size > 1024 * 1024 then
    file_win_set(win, vim.fn.fnamemodify(path, ":t"), { "Large file > 1MB" })
    return
  end
  if stat.size == 0 then
    file_win_set(win, vim.fn.fnamemodify(path, ":t"), { "Empty file" })
    return
  end

  local f = io.open(path, "r")
  if not f then
    file_win_set(win, " File ", { "Cannot read file" })
    return
  end
  local lines = {}
  for line in f:lines() do
    if #line > 500 then
      line = line:sub(1, 500) .. "..."
    end
    if line:find("[%z\1-\8\11\12\14-\31]") then
      f:close()
      file_win_set(win, vim.fn.fnamemodify(path, ":t"), { "Binary file" })
      return
    end
    lines[#lines + 1] = line
    if #lines >= 4000 then
      lines[#lines + 1] = "..."
      break
    end
  end
  f:close()

  file_win_set(win, vim.fn.fnamemodify(path, ":t"), lines)
  apply_open_syntax(path, win.buf)
end

---@param picker snacks.Picker
local function highlight_cursor(picker)
  local state = state_of(picker)
  local preview = picker.preview
  if not state or not preview or not preview.win:valid() then
    return
  end
  local buf = preview.win.buf
  vim.api.nvim_buf_clear_namespace(buf, NS_CUR, 0, -1)
  if #state.rows == 0 then
    update_file_preview(picker)
    return
  end
  state.cursor = math.max(1, math.min(state.cursor, #state.rows))
  vim.api.nvim_buf_set_extmark(buf, NS_CUR, state.cursor - 1, 0, {
    line_hl_group = "CursorLine",
  })
  if preview.win:win_valid() then
    pcall(vim.api.nvim_win_set_cursor, preview.win.win, { state.cursor, 0 })
    preview:wo({ cursorline = true })
  end
  update_file_preview(picker)
end

---@param picker snacks.Picker
---@param preview snacks.picker.Preview
local function render(picker, preview)
  local state = state_of(picker)
  if not state or not preview.win:valid() then
    return
  end

  state.rows = flatten(state)
  if state.focus_path then
    for i, row in ipairs(state.rows) do
      if row.path == state.focus_path then
        state.cursor = i
        break
      end
    end
    state.focus_path = nil
  end
  if #state.rows == 0 then
    state.cursor = 1
  else
    state.cursor = math.max(1, math.min(state.cursor, #state.rows))
  end

  preview:reset()
  preview:minimal()
  preview:set_title(vim.fn.fnamemodify(state.root, ":t"))
  preview:wo({ cursorline = true, wrap = false })

  local icons = picker.opts.icons or {}
  local tree_icons = icons.tree or { vertical = "│ ", middle = "├╴", last = "└╴" }
  local file_icons = icons.files or {}

  local lines = {}
  local marks = {}

  if #state.rows == 0 then
    lines[1] = "(empty)"
    marks[1] = { { 0, 7, "Comment" } }
  else
    for i, row in ipairs(state.rows) do
      local prefix_parts = {}
      for _, ancestor_last in ipairs(row.ancestors) do
        prefix_parts[#prefix_parts + 1] = ancestor_last and "  " or tree_icons.vertical
      end
      prefix_parts[#prefix_parts + 1] = row.last and tree_icons.last or tree_icons.middle
      local prefix = table.concat(prefix_parts)

      local cat = row.dir and "directory" or "file"
      local icon, icon_hl = Snacks.util.icon(row.name, cat, { fallback = file_icons })
      if row.dir and row.open and file_icons.dir_open then
        icon = file_icons.dir_open
      end
      icon = icon or (row.dir and "󰉋 " or "󰈔 ")
      if not icon:match("%s$") then
        icon = icon .. " "
      end

      local name_hl = row.dir and "SnacksPickerDirectory" or "SnacksPickerFile"
      local line = prefix .. icon .. row.name
      lines[i] = line

      local col = 0
      local row_marks = {}
      if #prefix > 0 then
        row_marks[#row_marks + 1] = { col, col + #prefix, "SnacksPickerTree" }
        col = col + #prefix
      end
      row_marks[#row_marks + 1] = { col, col + #icon, icon_hl or "SnacksPickerIcon" }
      col = col + #icon
      row_marks[#row_marks + 1] = { col, col + #row.name, name_hl }
      marks[i] = row_marks
    end
  end

  preview:set_lines(lines)
  local buf = preview.win.buf
  vim.api.nvim_buf_clear_namespace(buf, NS_TREE, 0, -1)
  for i, row_marks in ipairs(marks) do
    for _, mark in ipairs(row_marks) do
      vim.api.nvim_buf_set_extmark(buf, NS_TREE, i - 1, mark[1], {
        end_col = mark[2],
        hl_group = mark[3],
      })
    end
  end
  highlight_cursor(picker)
end

---@param ctx snacks.picker.preview.ctx
local function preview_tree(ctx)
  local dir = ctx.item and Snacks.picker.util.dir(ctx.item)
  if not dir or vim.fn.isdirectory(dir) ~= 1 then
    return Snacks.picker.preview.directory(ctx)
  end
  ensure_state(ctx.picker, dir)
  render(ctx.picker, ctx.preview)
end

---@param picker snacks.Picker
---@return directory_picker.Row?
current_row = function(picker)
  local state = state_of(picker)
  if not state or #state.rows == 0 then
    return nil
  end
  return state.rows[state.cursor]
end

---Path of the row under the tree-preview cursor. Falls back to the directory
---selected in the list — the tree is empty for a leaf folder, and the preview
---is a plain dir listing when the item is not a directory.
---@param picker snacks.Picker
---@return string?
local function current_path(picker)
  local row = current_row(picker)
  local path = row and row.path
  if not path then
    local item = picker:current()
    path = item and Snacks.picker.util.dir(item)
  end
  return path
end

---Mirror of the ff pickers' path/file copy keys: <C-y> realpath, <C-S-y>
---relative path, <C-c> filesystem object. The picker stays open.
---@param picker snacks.Picker
---@param map fun(path: string): string
---@param label string
local function copy_current(picker, map, label)
  local path = current_path(picker)
  if not path then
    vim.notify("No path under the cursor", vim.log.levels.WARN)
    return
  end

  local copied = map(path)
  require("utils.clipboard").copy_paths({ copied })
  vim.notify(label .. " copied: " .. copied)
end

---@param picker snacks.Picker
local function copy_current_realpath(picker)
  copy_current(picker, require("utils.clipboard").realpath, "Realpath")
end

---@param picker snacks.Picker
local function copy_current_relpath(picker)
  copy_current(picker, require("utils.clipboard").relpath, "Relative path")
end

---Copy the filesystem object under the tree-preview cursor (nvim-tree `C` / <C-c>).
---@param picker snacks.Picker
local function copy_current_fs_object(picker)
  local path = current_path(picker)
  if not path then
    vim.notify("No path under the cursor", vim.log.levels.WARN)
    return
  end
  require("utils.clipboard").copy_fs_object(path)
end

---Open the file under the tree-preview cursor with the system app (<leader>op / <C-o>).
---@param picker snacks.Picker
local function open_current_with_system(picker)
  local path = current_path(picker)
  if not path then
    vim.notify("No path under the cursor", vim.log.levels.WARN)
    return
  end
  require("utils.clipboard").open_path(require("utils.clipboard").realpath(path))
end

---@param picker snacks.Picker
---@param delta integer
local function move_cursor(picker, delta)
  local state = state_of(picker)
  if not state or #state.rows == 0 then
    return
  end
  state.cursor = math.max(1, math.min(#state.rows, state.cursor + delta))
  highlight_cursor(picker)
end

---@param picker snacks.Picker
---@param up? boolean
local function scroll_file(picker, up)
  local win = picker.layout and picker.layout.wins and picker.layout.wins.file
  if not win or not win:win_valid() then
    return
  end
  win:scroll(up)
end

local function reveal_in_nvim_tree(path)
  vim.schedule(function()
    local ok, api = pcall(require, "nvim-tree.api")
    if not ok then
      return
    end
    api.tree.find_file({
      buf = path,
      open = true,
      focus = true,
      update_root = false,
    })
    api.node.open.edit()
  end)
end

---Open the row under the tree-preview cursor with `cmd`, mirroring <CR>/<C-CR>.
---Directories are handed to nvim-tree instead, since :edit-ing one is meaningless.
---@param picker snacks.Picker
---@param cmd "edit"|"split"|"vsplit"|"tabedit"
local function open_row(picker, cmd)
  local row = current_row(picker)
  if not row then
    return
  end
  picker:close()
  if row.dir then
    reveal_in_nvim_tree(row.path)
    return
  end
  vim.schedule(function()
    vim.cmd(cmd .. " " .. vim.fn.fnameescape(row.path))
  end)
end

---@param cwd? string
function M.open(cwd)
  cwd = cwd or vim.uv.cwd() or vim.fn.getcwd()
  local cmd, args
  if vim.fn.executable("fd") == 1 then
    cmd, args = "fd", { "--type", "d", "--color", "never", "-E", ".git" }
  elseif vim.fn.executable("fdfind") == 1 then
    cmd, args = "fdfind", { "--type", "d", "--color", "never", "-E", ".git" }
  else
    cmd, args = "find", { ".", "-type", "d", "-not", "-path", "*/.git/*" }
  end

  local preview_keys = {
    ["<c-j>"] = { "dir_preview_down", mode = { "i", "n" } },
    ["<c-k>"] = { "dir_preview_up", mode = { "i", "n" } },
    ["<c-h>"] = { "dir_preview_close", mode = { "i", "n" } },
    ["<c-l>"] = { "dir_preview_open", mode = { "i", "n" } },
    ["<c-d>"] = { "dir_file_scroll_down", mode = { "i", "n" } },
    ["<c-u>"] = { "dir_file_scroll_up", mode = { "i", "n" } },
    ["<C-CR>"] = { "dir_preview_edit", mode = { "i", "n" } },
    ["<c-s>"] = { "dir_preview_split", mode = { "i", "n" } },
    ["<c-v>"] = { "dir_preview_vsplit", mode = { "i", "n" } },
    ["<c-t>"] = { "dir_preview_tabedit", mode = { "i", "n" } },
    ["<c-y>"] = { "dir_copy_realpath", mode = { "i", "n" } },
    ["<c-s-y>"] = { "dir_copy_relpath", mode = { "i", "n" } },
    ["<c-c>"] = { "dir_copy_fs_object", mode = { "i", "n" } },
    ["<c-o>"] = { "dir_preview_system_open", mode = { "i", "n" } },
  }

  -- 30% + 20% + 45% of the editor; picker width is that 95% total.
  local list_w, tree_w, file_w = 0.30 / 0.95, 0.20 / 0.95, 0.45 / 0.95
  ---@type snacks.Picker?
  local picker_ref

  local file_win = Snacks.win({
    show = false,
    enter = false,
    border = true,
    title = " File ",
    title_pos = "center",
    minimal = false,
    wo = {
      number = true,
      relativenumber = false,
      cursorline = false,
      wrap = false,
      signcolumn = "no",
      winhighlight = Snacks.picker.highlight.winhl("SnacksPickerPreview"),
    },
    bo = {
      buftype = "nofile",
      bufhidden = "wipe",
      swapfile = false,
    },
    keys = {
      ["<c-j>"] = function()
        if picker_ref then
          move_cursor(picker_ref, 1)
        end
      end,
      ["<c-k>"] = function()
        if picker_ref then
          move_cursor(picker_ref, -1)
        end
      end,
      ["<c-h>"] = function()
        if picker_ref then
          picker_ref:action("dir_preview_close")
        end
      end,
      ["<c-l>"] = function()
        if picker_ref then
          picker_ref:action("dir_preview_open")
        end
      end,
      ["<c-d>"] = function()
        if picker_ref then
          scroll_file(picker_ref, false)
        end
      end,
      ["<c-u>"] = function()
        if picker_ref then
          scroll_file(picker_ref, true)
        end
      end,
      ["<C-CR>"] = function()
        if picker_ref then
          picker_ref:action("dir_preview_edit")
        end
      end,
      ["<c-s>"] = function()
        if picker_ref then
          picker_ref:action("dir_preview_split")
        end
      end,
      ["<c-v>"] = function()
        if picker_ref then
          picker_ref:action("dir_preview_vsplit")
        end
      end,
      ["<c-t>"] = function()
        if picker_ref then
          picker_ref:action("dir_preview_tabedit")
        end
      end,
      ["<c-y>"] = function()
        if picker_ref then
          picker_ref:action("dir_copy_realpath")
        end
      end,
      ["<c-s-y>"] = function()
        if picker_ref then
          picker_ref:action("dir_copy_relpath")
        end
      end,
      ["<c-c>"] = function()
        if picker_ref then
          picker_ref:action("dir_copy_fs_object")
        end
      end,
      ["<c-o>"] = function()
        if picker_ref then
          picker_ref:action("dir_preview_system_open")
        end
      end,
      ["<Esc>"] = function()
        if picker_ref then
          picker_ref:close()
        end
      end,
      q = function()
        if picker_ref then
          picker_ref:close()
        end
      end,
    },
  })

  local picker = Snacks.picker({
    find = false,
    show_empty = true,
    title = "Directories: " .. vim.fn.fnamemodify(cwd, ":t"),
    cwd = cwd,
    format = "file",
    preview = preview_tree,
    layout = {
      layout = {
        box = "horizontal",
        width = 0.95,
        height = 0.95,
        {
          box = "vertical",
          border = true,
          title = "{title} {live} {flags}",
          width = list_w,
          { win = "input", height = 1, border = "bottom" },
          { win = "list", border = "none" },
        },
        { win = "preview", title = "{preview}", border = true, width = tree_w },
        { win = "file", title = " File ", border = true, width = file_w },
      },
    },
    finder = function(_, ctx)
      -- Always include cwd itself so leaf folders (no subdirs) still open.
      local inner = require("snacks.picker.source.proc").proc({
        cmd = cmd,
        args = args,
        cwd = cwd,
        transform = function(item)
          if item.text == "." or item.text == "./" then
            return false
          end
          item.file = item.text
          item.dir = true
          item.cwd = cwd
        end,
      }, ctx)
      return function(cb)
        cb({
          text = ".",
          file = ".",
          dir = true,
          cwd = cwd,
        })
        inner(cb)
      end
    end,
    confirm = function(picker, item)
      picker:close()
      local dir = item and Snacks.picker.util.dir(item)
      if not dir or vim.fn.isdirectory(dir) ~= 1 then
        vim.notify("Invalid directory: " .. tostring(dir or ""), vim.log.levels.ERROR)
        return
      end
      reveal_in_nvim_tree(dir)
    end,
    actions = {
      dir_copy_realpath = copy_current_realpath,
      dir_copy_relpath = copy_current_relpath,
      dir_copy_fs_object = copy_current_fs_object,
      dir_preview_system_open = open_current_with_system,
      dir_preview_down = function(picker)
        move_cursor(picker, 1)
      end,
      dir_preview_up = function(picker)
        move_cursor(picker, -1)
      end,
      dir_file_scroll_down = function(picker)
        scroll_file(picker, false)
      end,
      dir_file_scroll_up = function(picker)
        scroll_file(picker, true)
      end,
      dir_preview_open = function(picker)
        local state = state_of(picker)
        local row = current_row(picker)
        if not state or not row or not row.dir then
          return
        end
        if row.open then
          if state.cursor < #state.rows then
            state.cursor = state.cursor + 1
            highlight_cursor(picker)
          end
          return
        end
        state.expanded[row.path] = true
        state.focus_path = row.path
        render(picker, picker.preview)
      end,
      dir_preview_close = function(picker)
        local state = state_of(picker)
        local row = current_row(picker)
        if not state or not row then
          return
        end
        if row.dir and row.open then
          state.expanded[row.path] = nil
          state.focus_path = row.path
        else
          local parent = vim.fn.fnamemodify(row.path, ":h")
          if parent == state.root or parent == "" or not state.expanded[parent] then
            return
          end
          state.expanded[parent] = nil
          state.focus_path = parent
        end
        render(picker, picker.preview)
      end,
      dir_preview_edit = function(picker)
        open_row(picker, "edit")
      end,
      dir_preview_split = function(picker)
        open_row(picker, "split")
      end,
      dir_preview_vsplit = function(picker)
        open_row(picker, "vsplit")
      end,
      dir_preview_tabedit = function(picker)
        open_row(picker, "tabedit")
      end,
    },
    win = {
      input = { keys = preview_keys },
      list = {
        keys = {
          ["<c-j>"] = "dir_preview_down",
          ["<c-k>"] = "dir_preview_up",
          ["<c-h>"] = "dir_preview_close",
          ["<c-l>"] = "dir_preview_open",
          ["<c-d>"] = "dir_file_scroll_down",
          ["<c-u>"] = "dir_file_scroll_up",
          ["<C-CR>"] = "dir_preview_edit",
          ["<c-s>"] = "dir_preview_split",
          ["<c-v>"] = "dir_preview_vsplit",
          ["<c-t>"] = "dir_preview_tabedit",
          ["<c-y>"] = "dir_copy_realpath",
          ["<c-s-y>"] = "dir_copy_relpath",
          ["<c-c>"] = "dir_copy_fs_object",
          ["<c-o>"] = "dir_preview_system_open",
        },
      },
      preview = {
        keys = {
          ["<c-j>"] = "dir_preview_down",
          ["<c-k>"] = "dir_preview_up",
          ["<c-h>"] = "dir_preview_close",
          ["<c-l>"] = "dir_preview_open",
          ["<c-d>"] = "dir_file_scroll_down",
          ["<c-u>"] = "dir_file_scroll_up",
          ["<C-CR>"] = "dir_preview_edit",
          ["<c-s>"] = "dir_preview_split",
          ["<c-v>"] = "dir_preview_vsplit",
          ["<c-t>"] = "dir_preview_tabedit",
          ["<c-y>"] = "dir_copy_realpath",
          ["<c-s-y>"] = "dir_copy_relpath",
          ["<c-c>"] = "dir_copy_fs_object",
          ["<c-o>"] = "dir_preview_system_open",
        },
      },
    },
    on_show = function(p)
      update_file_preview(p)
    end,
  })

  if not picker then
    file_win:destroy()
    return
  end
  picker_ref = picker
  picker.layout.wins.file = file_win
  picker.layout.win_opts.file = vim.deepcopy(file_win.opts)
  picker:find()
end

return M
