local notes_vault = "~/Notes"

--- Read Obsidian app daily-note settings from `<vault>/.obsidian/daily-notes.json`.
---@param vault string
---@return obsidian.config.DailyNotesOpts
local function daily_notes_from_vault(vault)
  vault = vim.fs.normalize(vim.fn.expand(vault))
  local config_path = vim.fs.joinpath(vault, ".obsidian", "daily-notes.json")

  ---@type obsidian.config.DailyNotesOpts
  local opts = {
    enabled = true,
    workdays_only = false,
  }

  if vim.fn.filereadable(config_path) ~= 1 then
    return opts
  end

  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(config_path), "\n"))
  if not ok or type(data) ~= "table" then
    return opts
  end

  if type(data.folder) == "string" and data.folder ~= "" then
    opts.folder = data.folder:gsub("^/", "")
  end

  if type(data.format) == "string" and data.format ~= "" then
    opts.date_format = data.format
  end

  if type(data.template) == "string" and data.template ~= "" then
    local template = data.template:gsub("^/", "")
    opts.template = template:match("%.md$") and template or (template .. ".md")
  end

  return opts
end

return {
  {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  cmd = { "Obsidian" },
  event = {
    "BufReadPre " .. vim.fn.expand(notes_vault) .. "/**/*.md",
    "BufNewFile " .. vim.fn.expand(notes_vault) .. "/**/*.md",
  },
  ---@module "obsidian"
  ---@type obsidian.config
  opts = {
    legacy_commands = false,

    workspaces = {
      {
        name = "notes",
        path = notes_vault,
        overrides = {
          daily_notes = daily_notes_from_vault(notes_vault),
        },
      },
    },

    notes_subdir = "notes",
    log_level = vim.log.levels.INFO,
    new_notes_location = "notes_subdir",

    completion = {
      min_chars = 2,
    },

    link = {
      style = "wiki",
      format = "shortest",
    },

    ---@param title string|?
    ---@return string
    note_id_func = function(title)
      local suffix = ""
      if title ~= nil then
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return tostring(os.time()) .. "-" .. suffix
    end,

    ---@param spec { id: string, dir: obsidian.Path, title: string|? }
    ---@return string|obsidian.Path
    note_path_func = function(spec)
      local path = spec.dir / tostring(spec.id)
      return path:with_suffix(".md")
    end,

    frontmatter = {
      enabled = true,
      ---@return table<string, any>
      func = function(note)
        if note.title then
          note:add_alias(note.title)
        end

        local out = { id = note.id, aliases = note.aliases, tags = note.tags }

        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end

        return out
      end,
    },

    templates = {
      folder = "templates",
      date_format = "YYYY-MM-DD",
      time_format = "HH:mm",
      substitutions = {},
    },

    open = {
      use_advanced_uri = false,
    },

    picker = {
      name = "telescope.nvim",
      note_mappings = {
        new = "<C-x>",
        insert_link = "<C-l>",
      },
      tag_mappings = {
        tag_note = "<C-x>",
        insert_tag = "<C-l>",
      },
    },

    search = {
      sort_by = "modified",
      sort_reversed = true,
      max_lines = 1000,
    },

    open_notes_in = "current",

    callbacks = {
      ---@param note obsidian.Note
      enter_note = function(_)
        local actions = require("obsidian.actions")
        vim.keymap.set("n", "<leader>ch", actions.toggle_checkbox, {
          buffer = true,
          desc = "Toggle Obsidian checkbox",
        })
      end,
    },

    ui = {
      enable = true,
      update_debounce = 200,
      max_file_length = 5000,
      checkboxes = {
        [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
        ["x"] = { char = "", hl_group = "ObsidianDone" },
        [">"] = { char = "", hl_group = "ObsidianRightArrow" },
        ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
        ["!"] = { char = "", hl_group = "ObsidianImportant" },
      },
      bullets = { char = "•", hl_group = "ObsidianBullet" },
      external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
      reference_text = { hl_group = "ObsidianRefText" },
      highlight_text = { hl_group = "ObsidianHighlightText" },
      tags = { hl_group = "ObsidianTag" },
      block_ids = { hl_group = "ObsidianBlockID" },
      hl_groups = {
        ObsidianTodo = { bold = true, fg = "#f78c6c" },
        ObsidianDone = { bold = true, fg = "#89ddff" },
        ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
        ObsidianTilde = { bold = true, fg = "#ff5370" },
        ObsidianImportant = { bold = true, fg = "#d73128" },
        ObsidianBullet = { bold = true, fg = "#89ddff" },
        ObsidianRefText = { underline = true, fg = "#c792ea" },
        ObsidianExtLinkIcon = { fg = "#c792ea" },
        ObsidianTag = { italic = true, fg = "#89ddff" },
        ObsidianBlockID = { italic = true, fg = "#89ddff" },
        ObsidianHighlightText = { bg = "#75662e" },
      },
    },

    attachments = {
      folder = "assets/imgs",
      img_name_func = function()
        return string.format("%s-", os.time())
      end,
      ---@param path obsidian.Path
      img_text_func = function(path)
        local client = require("obsidian").get_client()
        path = client:vault_relative_path(path) or path
        return string.format("![%s](%s)", path.name, path)
      end,
    },
  },
  },
}
