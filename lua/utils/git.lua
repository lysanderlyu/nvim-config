local M = {}

-- Skip these when walking *down* into a parent folder looking for a repo.
-- Do not skip names that people use as project folders (build, target, …).
local SKIP_DOWN = {
  [".git"] = true,
  [".cache"] = true,
  [".venv"] = true,
  [".mypy_cache"] = true,
  [".tox"] = true,
  [".Trash"] = true,
  node_modules = true,
  venv = true,
}

local function norm(path)
  if not path or path == "" then
    return nil
  end
  return vim.fs.normalize(path):gsub("/+$", "")
end

---Canonical path: follow every symlink (file and parents).
---If `path` does not exist, resolve the deepest existing parent and append the rest.
---@param path string
---@return string|nil
function M.realpath(path)
  if not path or path == "" then
    return nil
  end
  path = vim.fn.fnamemodify(path, ":p")
  local real = vim.uv.fs_realpath(path)
  if real then
    return norm(real)
  end

  -- Dangling link / unsaved name: resolve the longest existing prefix.
  local tail, parent = {}, path
  while parent and parent ~= "" do
    local name = vim.fn.fnamemodify(parent, ":t")
    local next_parent = vim.fn.fnamemodify(parent, ":h")
    if name ~= "" and name ~= parent then
      table.insert(tail, 1, name)
    end
    if next_parent == parent then
      break
    end
    parent = next_parent
    real = vim.uv.fs_realpath(parent)
    if real then
      if #tail > 0 then
        real = real .. "/" .. table.concat(tail, "/")
      end
      return norm(real)
    end
  end

  return norm(vim.fn.resolve(path))
end

local function dir_of(path)
  -- Resolve the file/dir *first*. Taking `:h` of a symlink-to-file would
  -- search the link's parent instead of the target's git repo.
  local real = M.realpath(path)
  if not real then
    return nil
  end
  if vim.fn.isdirectory(real) == 1 then
    return real
  end
  return vim.fn.fnamemodify(real, ":h")
end

---Resolve work tree + git dir from any path inside a repo (git walks up).
---@param dir string
---@return { root: string, gitdir: string }|nil
local function toplevel(dir)
  local out = vim.fn.systemlist({
    "git",
    "-C",
    dir,
    "rev-parse",
    "--show-toplevel",
    "--absolute-git-dir",
  })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
    return nil
  end
  return {
    root = out[1],
    gitdir = out[2] or (out[1] .. "/.git"),
  }
end

---Breadth-first: first `.git` at the smallest depth (alphabetical if tied).
---Symlink directories are resolved so a linked project is still found.
---@param start string
---@param max_depth? integer
---@return { root: string, gitdir: string }|nil
local function walk_down(start, max_depth)
  max_depth = max_depth or 8
  start = M.realpath(start) or start
  local level = { start }
  local seen = { [start] = true }
  for _ = 0, max_depth do
    local hits = {}
    local next_level = {}
    for _, dir in ipairs(level) do
      if vim.uv.fs_stat(dir .. "/.git") then
        hits[#hits + 1] = dir
      else
        local handle = vim.uv.fs_scandir(dir)
        if handle then
          while true do
            local name, typ = vim.uv.fs_scandir_next(handle)
            if not name then
              break
            end
            if not SKIP_DOWN[name] then
              local child = dir .. "/" .. name
              if typ == "directory" or typ == "link"
                  or (typ == nil and vim.fn.isdirectory(child) == 1) then
                child = vim.uv.fs_realpath(child) or child
                child = norm(child) or child
                if not seen[child] then
                  seen[child] = true
                  next_level[#next_level + 1] = child
                end
              end
            end
          end
        end
      end
    end
    if #hits > 0 then
      table.sort(hits)
      return toplevel(hits[1])
    end
    if #next_level == 0 then
      return nil
    end
    level = next_level
  end
  return nil
end

---@param start? string
---@return string[]
local function start_dirs(start)
  if start and start ~= "" then
    local dir = dir_of(start)
    return dir and { dir } or {}
  end

  local dirs, seen = {}, {}
  local function add(path)
    local dir = dir_of(path)
    if not dir or seen[dir] then
      return
    end
    seen[dir] = true
    dirs[#dirs + 1] = dir
  end

  local buf = vim.api.nvim_buf_get_name(0)
  if buf ~= "" then
    add(buf)
  end
  add(vim.uv.cwd() or vim.fn.getcwd())
  return dirs
end

local function notify_root(info)
  local cwd = norm(vim.uv.cwd() or vim.fn.getcwd())
  local root = norm(info.root)
  if cwd and root and cwd ~= root then
    vim.notify("Git repo: " .. vim.fn.fnamemodify(info.root, ":~"), vim.log.levels.INFO)
  end
end

---Repo-relative path for a file, using its realpath so symlink buffers match.
---@param info { root: string }
---@param file string
---@return string|nil
function M.relpath(info, file)
  file = M.realpath(file) or file
  local out = vim.fn.systemlist({
    "git",
    "-c",
    "core.quotepath=false",
    "-C",
    info.root,
    "ls-files",
    "--full-name",
    "--",
    file,
  })
  if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
    return out[1]
  end
  local root = norm(info.root)
  local real = M.realpath(file)
  if root and real and real:sub(1, #root + 1) == root .. "/" then
    return real:sub(#root + 2)
  end
  return nil
end

---Run git in a repo and return stdout, or nil on failure.
---@param root string
---@param args string[]
---@return string|nil
local function capture(root, args)
  local cmd = { "git", "-c", "core.quotepath=false", "-C", root }
  vim.list_extend(cmd, args)
  local out = vim.system(cmd, { text = true }):wait()
  if out.code ~= 0 then
    return nil
  end
  return out.stdout
end

---Repo-relative paths whose history belongs to `rel`: the path itself followed
---by every name it was renamed from, newest first. Feed this to plain `git log`
---as a pathspec instead of using `--follow`.
---
---Why not `--follow`: it re-runs rename detection against whatever tree the name
---disappears in, so a boilerplate file chains through bogus 100%-similarity
---matches back to an import-style root commit and detection then runs over that
---whole tree. Measured 125s / 2.5GB on one .mk file. It also disables
---path-limiting, so changed-path Bloom filters cannot be used. Instead walk name
---by name, asking only the single commit that added each name where it came
---from; that diff covers just that commit's files, so it stays in the
---milliseconds.
---@param info { root: string }
---@param rel string repo-relative path
---@return string[] pathspec: at least `rel`
function M.history_pathspec(info, rel)
  local names = {}
  local name = rel

  -- Depth cap: a rename chain this long is not worth more git calls.
  for _ = 1, 10 do
    names[#names + 1] = name

    local log = capture(info.root, { "log", "--format=%H", "--", name })
    local added
    for _, sha in ipairs(vim.split(log or "", "\n", { trimempty = true })) do
      added = sha
    end
    if not added then
      break
    end

    -- Parents from an unfiltered rev-list: under a pathspec, history
    -- simplification rewrites them away and every commit that adds a name
    -- looks parentless. A root commit ends the chain — nothing to rename from.
    local parents = capture(info.root, { "rev-list", "--parents", "-n", "1", added })
    if not parents or #vim.split(vim.trim(parents), "%s+") < 2 then
      break
    end

    local renames = capture(info.root, {
      "show", "-M", "-z", "--name-status", "--diff-filter=R", "--format=", added,
    })
    -- -z record: "R<similarity>", old, new
    local fields = vim.split(renames or "", "\0", { trimempty = true })
    local from
    for i = 1, #fields - 2 do
      if fields[i]:find("^R%d+$") and fields[i + 2] == name then
        from = fields[i + 1]
        break
      end
    end
    if not from then
      break
    end
    name = from
  end

  return names
end

---Nearest git work tree for a path (or the current file, then cwd).
---Walks up first (normal git), then searches downward for a nested `.git`.
---Start paths are realpath-resolved so a symlink file/dir still finds its repo.
---@param opts? { start?: string, silent?: boolean }
---@return { root: string, gitdir: string, file?: string }|nil
function M.nearest(opts)
  opts = opts or {}
  local dirs = start_dirs(opts.start)
  local start_file = M.realpath(opts.start or vim.api.nvim_buf_get_name(0))

  local function finish(info)
    info.file = start_file
    if not opts.silent then
      notify_root(info)
    end
    return info
  end

  for _, dir in ipairs(dirs) do
    local info = toplevel(dir)
    if info then
      return finish(info)
    end
  end

  for _, dir in ipairs(dirs) do
    local info = walk_down(dir)
    if info then
      return finish(info)
    end
  end

  if not opts.silent then
    vim.notify("Not a git repo (no .git above or under this path)", vim.log.levels.ERROR)
  end
  return nil
end

---Git dir to hand to fugitive for this repo.
---
---Fugitive derives the work tree from the git dir's `core.worktree`, or, for a
---gitfile, from the gitfile's own location. Under `--separate-git-dir` the
---absolute git dir is external and carries no `core.worktree`, so fugitive
---rejects it with "core.worktree is required when using an external Git dir".
---`<root>/.git` is a gitfile there that points back at the work tree, so both
---`b:git_dir` and the `fugitive://` URLs built from it resolve correctly.
---Submodule and linked-worktree git dirs do set `core.worktree`, so either form
---works for those — but the gitfile is correct in every layout.
---@param info { root: string, gitdir: string }
---@return string
function M.fugitive_dir(info)
  local root = norm(info.root)
  local gitfile = root and (root .. "/.git")
  if gitfile and vim.uv.fs_stat(gitfile) then
    return gitfile
  end
  return info.gitdir
end

---Point fugitive at this repo for the current buffer (`:Gtabedit`, `:Gvdiffsplit`).
---
---This only pins the buffer it runs in. `:Gtabedit` / `FugitiveFind` open *new*
---buffers that re-derive the repo from the URL, so those callers must build
---their URLs from `M.fugitive_dir(info)` too, not from `info.gitdir`.
---@param info { root: string, gitdir: string }
function M.detect(info)
  vim.b.git_dir = M.fugitive_dir(info)
end

return M
