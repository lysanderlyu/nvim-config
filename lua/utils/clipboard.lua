local M = {}

---Process-global FS clipboard. Kept on `_G` so it survives `utils.clipboard`
---module reloads (Lazy/`package.loaded` churn) between picker Ctrl-c and paste.
---@type string[]
_G.__nvim_fs_clipboard = _G.__nvim_fs_clipboard or {}

---Back-compat alias; prefer get/set helpers below.
M._fs_clipboard = _G.__nvim_fs_clipboard

---@return string[]
function M.get_fs_clipboard()
  local paths = _G.__nvim_fs_clipboard
  if type(paths) == "table" and #paths > 0 then
    return paths
  end
  return {}
end

---@param paths string[]
function M.set_fs_clipboard(paths)
  _G.__nvim_fs_clipboard = paths or {}
  M._fs_clipboard = _G.__nvim_fs_clipboard
end

---Paths remembered from Ctrl-c, or recovered from the OS / `+` register.
---@return string[]
local function resolve_fs_clipboard()
  local paths = M.get_fs_clipboard()
  if #paths > 0 then
    return paths
  end

  -- macOS: Ctrl-c puts a file URL on the pasteboard; recover that path.
  if vim.fn.has("mac") == 1 then
    local out = vim.fn.system({
      "osascript",
      "-e",
      [[try
  POSIX path of (the clipboard as «class furl»)
end try]],
    })
    if vim.v.shell_error == 0 then
      out = vim.trim(out or "")
      if out ~= "" then
        out = out:gsub("/$", "")
        if vim.uv.fs_stat(out) then
          M.set_fs_clipboard({ out })
          return M.get_fs_clipboard()
        end
      end
    end
  end

  -- Text paths on `+` (nvim-tree / copy_paths style).
  local reg = vim.fn.getreg("+")
  if type(reg) == "string" and reg ~= "" then
    local recovered = {}
    for _, line in ipairs(vim.split(reg, "\n", { plain = true, trimempty = true })) do
      line = vim.trim(line):gsub("^file://", "")
      if line ~= "" and vim.uv.fs_stat(line) then
        recovered[#recovered + 1] = vim.fn.fnamemodify(line, ":p"):gsub("/$", "")
      end
    end
    if #recovered > 0 then
      M.set_fs_clipboard(recovered)
      return recovered
    end
  end

  return {}
end

---Pick a free destination path under `dest_dir` (basename preserved; adds " copy").
---@param src string
---@param dest_dir string
---@return string|nil dest
---@return string|nil err
local function unique_dest_path(src, dest_dir)
  local name = vim.fn.fnamemodify(src:gsub("/$", ""), ":t")
  if name == "" or name == "." or name == ".." then
    return nil, "invalid name"
  end
  dest_dir = dest_dir:gsub("/$", "")
  local stem = vim.fn.fnamemodify(name, ":r")
  local ext = vim.fn.fnamemodify(name, ":e")
  -- Dotfiles like `.env`: `:r` is empty; keep the full name as the stem.
  if stem == "" then
    stem = name
    ext = ""
  end
  local suffix = ext ~= "" and ("." .. ext) or ""

  local dest = dest_dir .. "/" .. name
  if not vim.uv.fs_stat(dest) then
    return dest
  end
  for i = 1, 99 do
    local extra = i == 1 and " copy" or (" copy " .. i)
    dest = dest_dir .. "/" .. stem .. extra .. suffix
    if not vim.uv.fs_stat(dest) then
      return dest
    end
  end
  return nil, "no free name under " .. dest_dir
end

---Recursively copy `src` into `dest_dir` (basename preserved; renames on conflict).
---@param src string
---@param dest_dir string
---@return boolean ok
---@return string|nil err
---@return string|nil dest path written when ok
local function copy_into_dir(src, dest_dir)
  local dest, err = unique_dest_path(src, dest_dir)
  if not dest then
    return false, err
  end

  if vim.fn.isdirectory(src) == 1 then
    local code = vim.fn.system({ "cp", "-R", src, dest })
    if vim.v.shell_error ~= 0 then
      return false, (code ~= "" and code or "cp failed")
    end
    return true, nil, dest
  end

  local ok, copy_err = vim.uv.fs_copyfile(src, dest)
  if not ok then
    return false, copy_err or "fs_copyfile failed"
  end
  return true, nil, dest
end

---Directory under the nvim-tree cursor (file → parent). Opens the tree if needed.
---Reads the tree window cursor even when a picker float has focus.
---@return string|nil
local function nvim_tree_dest_dir()
  local ok, api = pcall(require, "nvim-tree.api")
  if not ok then
    return nil
  end

  if not api.tree.is_visible() then
    pcall(api.tree.open)
  end

  -- Prefer the explorer's own cursor lookup (uses tree winid, not current win).
  local node = api.tree.get_node_under_cursor()
  if (not node or not node.absolute_path) then
    local core_ok, core = pcall(require, "nvim-tree.core")
    local explorer = core_ok and core.get_explorer() or nil
    if explorer and explorer.get_node_at_cursor then
      node = explorer:get_node_at_cursor()
    end
  end

  if not node or not node.absolute_path then
    local core_ok, core = pcall(require, "nvim-tree.core")
    if core_ok then
      return core.get_cwd()
    end
    return nil
  end

  local path = node.absolute_path
  local is_dir = node.type == "directory"
    or (node.type == "link" and vim.fn.isdirectory(path) == 1)
    or vim.fn.isdirectory(path) == 1
  return is_dir and path or vim.fn.fnamemodify(path, ":h")
end

---Copy a filesystem object (file or directory) to the system clipboard so it
---can be pasted in a file manager. Same behaviour as nvim-tree `C`.
---Also remembers the path for picker <C-p> → paste into nvim-tree.
---@param path string|nil
---@param opts? { remember?: boolean } remember defaults to true
---@return boolean ok
function M.copy_fs_object(path, opts)
  opts = opts or {}
  if not path or path == "" then
    vim.notify("No path to copy", vim.log.levels.WARN)
    return false
  end

  path = vim.fn.fnamemodify(M.realpath(path), ":p"):gsub("/$", "")
  local name = vim.fn.fnamemodify(path, ":t")

  -- Remember before the OS call so paste never races an empty clipboard.
  if opts.remember ~= false then
    M.set_fs_clipboard({ path })
  end

  -- macOS
  if vim.fn.has("mac") == 1 then
    vim.fn.system({
      "osascript",
      "-e",
      string.format([[
        set theFile to POSIX file "%s"
        set the clipboard to theFile
      ]], path)
    })

  -- Windows / WSL
  elseif vim.fn.has("win32") == 1 or vim.fn.has("wsl") == 1 then
    local cmd = string.format(
      'powershell.exe -NoProfile -Command "Set-Clipboard -Path \'%s\'"',
      path
    )
    vim.fn.system(cmd)

  -- Linux
  else
    if vim.fn.executable("wl-copy") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | wl-copy -t text/uri-list", path)
      )
    elseif vim.fn.executable("xclip") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | xclip -selection clipboard -t text/uri-list", path)
      )
    elseif vim.fn.executable("xsel") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | xsel --clipboard --input", path)
      )
    else
      vim.notify("No clipboard tool found (wl-copy/xclip/xsel)", vim.log.levels.ERROR)
      return false
    end
  end

  vim.notify("Copied filesystem object: " .. name)
  return true
end

---Paste paths from the FS clipboard (set by <C-c> / `copy_fs_object`) into the
---directory under the nvim-tree cursor.
---@param paths? string[] override clipboard (e.g. picker selection)
---@return boolean ok
function M.paste_fs_to_nvim_tree(paths)
  -- Empty table is truthy in Lua — only treat non-empty lists as overrides.
  if type(paths) ~= "table" or #paths == 0 then
    paths = resolve_fs_clipboard()
  end
  if #paths == 0 then
    vim.notify("FS clipboard is empty (use Ctrl-c in a picker first)", vim.log.levels.WARN)
    return false
  end

  local dest_dir = nvim_tree_dest_dir()
  if not dest_dir or dest_dir == "" then
    vim.notify("No nvim-tree destination (open nvim-tree and put the cursor on a folder)", vim.log.levels.WARN)
    return false
  end

  local ok_count, err_count = 0, 0
  local last_dest ---@type string|nil
  for _, src in ipairs(paths) do
    src = M.realpath(src)
    if not vim.uv.fs_stat(src) then
      vim.notify("Missing: " .. src, vim.log.levels.ERROR)
      err_count = err_count + 1
    else
      local ok, err, dest = copy_into_dir(src, dest_dir)
      if ok then
        ok_count = ok_count + 1
        last_dest = dest
      else
        vim.notify("Paste failed: " .. (err or src), vim.log.levels.ERROR)
        err_count = err_count + 1
      end
    end
  end

  local api_ok, api = pcall(require, "nvim-tree.api")
  if api_ok then
    api.tree.reload()
    if last_dest then
      pcall(api.tree.find_file, { buf = last_dest, focus = false })
    end
  end

  if ok_count > 0 then
    vim.notify(
      string.format("Pasted %d item(s) → %s", ok_count, dest_dir),
      vim.log.levels.INFO
    )
  end
  return err_count == 0 and ok_count > 0
end

---nvim-tree `p`: use FS clipboard from picker <C-c> when the tree clipboard is empty.
function M.paste_fs_or_nvim_tree()
  local has_tree_clip = false
  local core_ok, core = pcall(require, "nvim-tree.core")
  if core_ok then
    local explorer = core.get_explorer()
    local clip = explorer and explorer.clipboard
    if clip and clip.data then
      has_tree_clip = #(clip.data.copy or {}) > 0 or #(clip.data.cut or {}) > 0
    end
  end

  if not has_tree_clip and #resolve_fs_clipboard() > 0 then
    M.paste_fs_to_nvim_tree()
    return
  end

  local api_ok, api = pcall(require, "nvim-tree.api")
  if api_ok then
    api.fs.paste()
  end
end

function M.copy_current_file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("No file associated with this buffer", vim.log.levels.WARN)
    return
  end
  M.copy_fs_object(path)
end

---Put paths on the system clipboard, and on the unnamed register so `p`
---pastes them too.
---@param paths string[]
---@return string text newline-joined as copied
function M.copy_paths(paths)
  local text = table.concat(paths, "\n")
  vim.fn.setreg("+", text) -- system clipboard
  vim.fn.setreg('"', text) -- unnamed, so `p` pastes them too
  return text
end

---Open `path` with the OS default app (same as <leader>op). Directories are refused.
---@param path string|nil
---@return boolean ok
function M.open_path(path)
  if not path or path == "" then
    vim.notify("No file to open", vim.log.levels.WARN)
    return false
  end
  if vim.fn.isdirectory(path) == 1 then
    vim.notify("Directory selected", vim.log.levels.INFO)
    return false
  end

  local cmd
  local sys = vim.loop.os_uname().sysname
  if sys == "Darwin" then
    cmd = { "open", path }
  elseif vim.fn.executable("wslview") == 1 then
    cmd = { "wslview", path }
  else
    cmd = { "xdg-open", path }
  end
  vim.fn.jobstart(cmd, { detach = true })
  return true
end

---Path of an fzf-lua picker line, tolerating icons and `:line:col` suffixes
---the way fzf-lua's own file actions do.
---@param entry string
---@param opts table|nil picker opts, used to resolve relative entries
---@return string|nil
local function picker_entry_path(entry, opts)
  local file = require("fzf-lua.path").entry_to_file(entry, opts)
  local path = file and file.path
  if not path or path == "" then
    return nil
  end
  return path
end

---Canonical absolute path: symlinks resolved, falling back to `path` when
---they cannot be.
---@param path string
---@return string
function M.realpath(path)
  return require("utils.git").realpath(path) or path
end

---`path` relative to the nearest git repo root, or to Neovim's cwd when there
---is no repo above it.
---@param path string
---@return string
function M.relpath(path)
  local git = require("utils.git")
  local info = git.nearest({ start = path, silent = true })
  -- No repo: Neovim's cwd is the next best base.
  return (info and git.relpath(info, path)) or vim.fn.fnamemodify(path, ":.")
end

---The two ways a picker copies a *path string*. `map` turns a path from the
---picker into the text to copy; `label` names it in the info message and in
---fzf's `?` help. Relpath help names <C-S-y> (forwarded from Neovim; fzf
---cannot bind Shift itself).
local MODES = {
  realpath = { label = "Realpath", header = "copy realpath", map = M.realpath },
  relpath = { label = "Relative path", header = "copy relative path (<C-S-y>)", map = M.relpath },
}

---fzf-lua action: copy the file(s) in the picker in the given `mode`.
---`{+}` expands to the entries toggled with <Tab>, or the entry under the
---cursor when nothing is toggled.
---
---Bind it with `exec_silent = true` so the picker stays open — a plain
---function action accepts-and-closes instead. <Esc> still aborts.
---@param selected string[]
---@param opts table
---@param mode "realpath"|"relpath"
local function fzf_copy_paths(selected, opts, mode)
  local paths = {}
  for _, entry in ipairs(selected or {}) do
    local path = picker_entry_path(entry, opts)
    if path then
      paths[#paths + 1] = MODES[mode].map(path)
    end
  end

  local utils = require("fzf-lua.utils")
  if #paths == 0 then
    utils.warn("No file under the cursor")
    return
  end

  local text = M.copy_paths(paths)
  local label = MODES[mode].label

  if #paths == 1 then
    utils.info(label .. " copied: " .. text)
  else
    utils.info(("%d %s copied"):format(#paths, label:lower() .. "s"))
  end
end

---@param selected string[]
---@param opts table
function M.fzf_copy_realpath(selected, opts)
  fzf_copy_paths(selected, opts, "realpath")
end

---@param selected string[]
---@param opts table
function M.fzf_copy_relpath(selected, opts)
  fzf_copy_paths(selected, opts, "relpath")
end

---fzf-lua action: copy the filesystem object under the cursor (pasteable in a
---file manager), same as nvim-tree `C`. Remembers paths for <C-p> paste.
---@param selected string[]
---@param opts table
function M.fzf_copy_fs_object(selected, opts)
  local paths = {}
  for _, entry in ipairs(selected or {}) do
    local path = picker_entry_path(entry, opts)
    if path then
      -- Always store absolute paths so paste still works after cwd changes.
      paths[#paths + 1] = vim.fn.fnamemodify(M.realpath(path), ":p"):gsub("/$", "")
    end
  end
  if #paths == 0 then
    require("fzf-lua.utils").warn("No file under the cursor")
    return
  end

  -- Remember first (process-global) so Ctrl-p never races an empty clipboard.
  M.set_fs_clipboard(paths)
  -- OS clipboard gets the first item (file managers usually expect one).
  M.copy_fs_object(paths[1], { remember = false })
  -- copy_fs_object with remember=false must not wipe multi-select.
  M.set_fs_clipboard(paths)
  if #paths > 1 then
    require("fzf-lua.utils").info(("%d items ready to paste (Ctrl-p)"):format(#paths))
  end
end

---fzf-lua action: paste FS clipboard into nvim-tree (companion to <C-c>).
---Falls back to the current selection when the clipboard is empty.
---@param selected string[]|nil
---@param opts table|nil
function M.fzf_paste_fs_to_nvim_tree(selected, opts)
  local paths = M.get_fs_clipboard()
  if #paths == 0 and selected and #selected > 0 then
    paths = {}
    for _, entry in ipairs(selected) do
      local path = picker_entry_path(entry, opts)
      if path then
        paths[#paths + 1] = vim.fn.fnamemodify(M.realpath(path), ":p"):gsub("/$", "")
      end
    end
  end
  -- nil (not {}) so paste_fs_to_nvim_tree can fall back to OS clipboard.
  local override = #paths > 0 and paths or nil
  vim.schedule(function()
    require("utils.clipboard").paste_fs_to_nvim_tree(override)
  end)
end

---fzf-lua action: open the entry under the cursor with the system app (<leader>op).
---@param selected string[]
---@param opts table
function M.fzf_open_with_system(selected, opts)
  local path = picker_entry_path(selected and selected[1], opts)
  if not path then
    require("fzf-lua.utils").warn("No file under the cursor")
    return
  end
  -- Prefer realpath so soft-linked picker entries open the real file.
  M.open_path(M.realpath(path))
end

---fzf key the relative-path copy hides behind, and the bytes a terminal sends
---for it. `alt-r` avoids fzf's own binds; <C-S-y> is forwarded from Neovim
---because fzf cannot distinguish Shift modifiers.
---@see M.picker_opts
local RELPATH_KEY = "alt-r"
local RELPATH_BYTES = "\27r"

---fzf-lua `actions` table for a file picker. Built fresh per picker: fzf-lua
---mutates the tables it is given.
---@return table
function M.path_actions()
  return {
    ["ctrl-y"] = {
      fn = M.fzf_copy_realpath,
      exec_silent = true,
      header = MODES.realpath.header,
    },
    [RELPATH_KEY] = {
      fn = M.fzf_copy_relpath,
      exec_silent = true,
      header = MODES.relpath.header,
    },
    ["ctrl-c"] = {
      fn = M.fzf_copy_fs_object,
      exec_silent = true,
      header = "copy file to clipboard",
    },
    ["ctrl-p"] = {
      fn = M.fzf_paste_fs_to_nvim_tree,
      exec_silent = true,
      header = "paste file into nvim-tree",
    },
    ["ctrl-o"] = {
      fn = M.fzf_open_with_system,
      exec_silent = true,
      header = "open with system app",
    },
  }
end

---Picker opts: <C-y> realpath, <C-S-y> relative path, <C-c> file object,
---<C-p> paste into nvim-tree, <C-o> open with system app.
---@param opts table fzf-lua picker opts; `actions` and `winopts` are kept
---@return table the same table
function M.picker_opts(opts)
  opts.actions = vim.tbl_extend("keep", opts.actions or {}, M.path_actions())
  opts.winopts = M.with_shift_path_keys(opts.winopts)
  return opts
end

---Wrap a picker's `winopts` so that <C-S-y> copies the relative path and
---<C-p> pastes into nvim-tree.
---
---fzf cannot bind Shift: it folds modifiers and ignores CSI-u encodings.
---Neovim does decode them, so a terminal-mode mapping on the fzf buffer gets
---the key first; forwarding <M-r> from there lets fzf expand `{+}` itself.
---
---<C-p> is also bound in terminal mode: fzf's default is "move up", and
---execute-silent binds for it are easy to lose; paste only needs our FS
---clipboard, so Neovim can handle it directly.
---@param winopts table|nil
---@return table
function M.with_shift_path_keys(winopts)
  winopts = winopts or {}
  local on_create = winopts.on_create

  winopts.on_create = function(e)
    if on_create then
      on_create(e)
    end

    local buf = e and e.bufnr
    if not (buf and vim.api.nvim_buf_is_valid(buf)) then
      return
    end

    vim.keymap.set("t", "<C-S-y>", function()
      vim.api.nvim_chan_send(vim.bo[buf].channel, RELPATH_BYTES)
    end, { buffer = buf, nowait = true, desc = "Copy relative path" })

    -- Require fresh so paste always sees the process-global FS clipboard.
    vim.keymap.set("t", "<C-p>", function()
      require("utils.clipboard").paste_fs_to_nvim_tree()
    end, { buffer = buf, nowait = true, desc = "Paste FS object into nvim-tree" })
  end

  return winopts
end

-- Back-compat alias (older call sites / comments).
M.with_shift_ctrl_c = M.with_shift_path_keys

function M.copy_fs_object_from_nvim_tree()
  local api = require("nvim-tree.api")
  local node = api.tree.get_node_under_cursor()
  if not node or not node.absolute_path then
    return
  end
  M.copy_fs_object(node.absolute_path)
end

return M
