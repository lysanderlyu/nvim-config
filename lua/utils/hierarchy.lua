---Path hierarchy helpers for buffer-scoped pickers (`<leader>[1-9]ss`, `<leader>-1ff`, …).
---Mirrors nvim-tree `[count]ss` / `-[1-9]ss`: walk from the **workdir / nvim-tree
---root** (not the git toplevel) down the current buffer path.

local M = {}

---@param path string|nil
---@return string|nil
local function norm(path)
  if not path or path == "" then
    return nil
  end
  -- Parentheses: gsub also returns a count; don't leak it to callers.
  return (vim.fs.normalize(path):gsub("/+$", ""))
end

---Absolute path of the current buffer (must be a named file).
---@return string|nil
function M.buffer_path()
  local name = vim.api.nvim_buf_get_name(0)
  if not name or name == "" then
    vim.notify("No file associated with this buffer", vim.log.levels.WARN)
    return nil
  end
  return require("utils.git").realpath(name) or vim.fn.fnamemodify(name, ":p")
end

---Directory of `path` (or of the current buffer): folder itself, else parent.
---@param path? string
---@return string|nil
function M.dir_of(path)
  path = path or M.buffer_path()
  if not path then
    return nil
  end
  if vim.fn.isdirectory(path) == 1 then
    return norm(path)
  end
  return norm(vim.fn.fnamemodify(path, ":h"))
end

---Hierarchy root: nvim-tree explorer cwd when the tree is open (same basis as
---tree `[1-9]ss`), otherwise Neovim's current working directory.
---@param _path? string unused; kept for call-site symmetry
---@return string
function M.project_root(_path)
  local ok, core = pcall(require, "nvim-tree.core")
  if ok and core.get_cwd then
    local tree_cwd = core.get_cwd()
    if type(tree_cwd) == "string" and tree_cwd ~= "" then
      return norm(tree_cwd) or tree_cwd
    end
  end
  return norm(vim.fn.getcwd()) or vim.fn.getcwd()
end

---Chain from workdir/tree root down to `path`: [root, root/a, root/a/b, …, path].
---@param path string
---@return string[]|nil
local function chain_from_root(path)
  path = norm(path)
  local root = M.project_root(path)
  if not path or not root then
    return nil
  end

  if path == root then
    return { root }
  end

  -- Prefer the configured root; if the buffer is outside it, fall back to cwd.
  if not vim.startswith(path, root .. "/") and path ~= root then
    root = norm(vim.fn.getcwd()) or root
    if not vim.startswith(path, root .. "/") and path ~= root then
      vim.notify("Buffer path is outside the current workdir", vim.log.levels.WARN)
      return nil
    end
  end

  local rel = path:sub(#root + 2) -- after "root/"
  local chain = { root }
  if rel and rel ~= "" then
    local acc = root
    for _, seg in ipairs(vim.split(rel, "/", { plain = true, trimempty = true })) do
      acc = acc .. "/" .. seg
      chain[#chain + 1] = acc
    end
  end
  return chain
end

---Directory at hierarchy depth `level` from the workdir/tree root along the buffer path.
---level 0 → current buffer dir; level 1 → first folder under the workdir, …
---@param level? integer
---@param path? string
---@return string|nil
function M.dir_at_hierarchy_level(level, path)
  level = level or 0
  path = path or M.buffer_path()
  if not path then
    return nil
  end

  if level == 0 then
    return M.dir_of(path)
  end

  local chain = chain_from_root(path)
  if not chain then
    return nil
  end

  -- chain[1] = root; level 1 → chain[2], same as nvim-tree.
  local target = chain[level + 1]
  if not target then
    vim.notify(
      string.format(
        "No directory at hierarchy level %d (path depth is %d)",
        level,
        math.max(#chain - 1, 0)
      ),
      vim.log.levels.WARN
    )
    return nil
  end
  return M.dir_of(target)
end

---N directory levels up from the buffer's directory toward the workdir/tree root.
---`-1` = parent of current file's dir, `-2` = grandparent, …
---@param n? integer
---@param path? string
---@return string|nil
function M.dir_n_levels_up(n, path)
  n = n or 0
  path = path or M.buffer_path()
  if not path then
    return nil
  end

  local cur = M.dir_of(path)
  if not cur then
    return nil
  end
  if n == 0 then
    return cur
  end

  local root = M.project_root(path)
  for _ = 1, n do
    if root and cur == root then
      vim.notify(
        string.format("Cannot go %d level(s) up (reached workdir root)", n),
        vim.log.levels.WARN
      )
      return nil
    end
    local parent = norm(vim.fn.fnamemodify(cur, ":h"))
    if not parent or parent == cur then
      vim.notify(
        string.format("Cannot go %d level(s) up (reached filesystem root)", n),
        vim.log.levels.WARN
      )
      return nil
    end
    cur = parent
  end
  return cur
end

return M
