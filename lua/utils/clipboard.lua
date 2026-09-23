local M = {}

---Copy a filesystem object (file or directory) to the system clipboard so it
---can be pasted in a file manager. Same behaviour as nvim-tree `C`.
---@param path string|nil
---@return boolean ok
function M.copy_fs_object(path)
  if not path or path == "" then
    vim.notify("No path to copy", vim.log.levels.WARN)
    return false
  end

  path = M.realpath(path)
  local name = vim.fn.fnamemodify(path, ":t")

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
---file manager), same as nvim-tree `C`.
---@param selected string[]
---@param opts table
function M.fzf_copy_fs_object(selected, opts)
  local path = picker_entry_path(selected and selected[1], opts)
  if not path then
    require("fzf-lua.utils").warn("No file under the cursor")
    return
  end
  M.copy_fs_object(path)
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
    ["ctrl-o"] = {
      fn = M.fzf_open_with_system,
      exec_silent = true,
      header = "open with system app",
    },
  }
end

---Picker opts: <C-y> realpath, <C-S-y> relative path, <C-c> file object,
---<C-o> open with system app.
---@param opts table fzf-lua picker opts; `actions` and `winopts` are kept
---@return table the same table
function M.picker_opts(opts)
  opts.actions = vim.tbl_extend("keep", opts.actions or {}, M.path_actions())
  opts.winopts = M.with_shift_path_keys(opts.winopts)
  return opts
end

---Wrap a picker's `winopts` so that <C-S-y> copies the relative path.
---
---fzf cannot bind Shift: it folds modifiers and ignores CSI-u encodings.
---Neovim does decode them, so a terminal-mode mapping on the fzf buffer gets
---the key first; forwarding <M-r> from there lets fzf expand `{+}` itself.
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
