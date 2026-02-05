return {
  {
    "potamides/pantran.nvim",
    config = function()
      require("pantran").setup({
        -- Default engine (can be "google", "deepl", "argos", "yandex", or "apertium")
        default_engine = "google",
        engines = {
          google = {
            fallback = {
              default_source = "auto",
              default_target = "zh",
            },
          },
        },
      })

      -- Keybindings
      local opts = { noremap = true, silent = true, expr = true }
      local pantran = require("pantran")
      local actions = require("pantran.ui.actions")

      -- Translate a motion (e.g., <leader>trip to translate a paragraph)
      vim.keymap.set("n", "<leader>tr", pantran.motion_translate, opts)

      -- Translate current line
      vim.keymap.set("n", "<leader>tl", function()
        return pantran.motion_translate() .. "_"
      end, opts)

      -- Translate selection in visual mode
      vim.keymap.set("x", "<leader>tr", pantran.motion_translate, opts)

      -- Quickly translate the current word
      vim.keymap.set("n", "T", function()
        return pantran.motion_translate() .. "iw"
      end, { noremap = true, silent = true, expr = true, desc = "Translate current word" })
    end,
  },
}

-- ==============================================================================
-- 5. Default Mappings                                 *pantran-default-mappings*
-- 
-- Default keybindings for various modes in the interactive translation UI. If not
-- otherwise specified actions live in the `actions` module. Replace actions
-- replace the text with which the translation window was initialized (e.g.,
-- through a range or a movement). Note that `<C-_>` is the key from pressing
-- `<C-/>`.
-- 
-- EDIT WINDOW                                              *pantran-edit-window*
-- 
-- │ Insert  │         Action          │              Description              │
-- │<C-c>    │close                    │Terminate current translation.         │
-- │<C-_>    │help                     │Show mappings in floating window.      │
-- │<C-y>    │yank_close_translation   │Yank translation and quit.             │
-- │<M-y>    │yank_close_input         │Yank input and quit.                   │
-- │<C-r>    │replace_close_translation│Replace text with translation and quit.│
-- │<M-r>    │replace_close_input      │Replace text with input and quit.      │
-- │<C-a>    │append_close_translation │Append translation to text and quit.   │
-- │<M-a>    │append_close_input       │Append input to text and quit.         │
-- │<C-e>    │select_engine            │Select a new translation engine.       │
-- │<C-s>    │select_source            │Select a new source language.          │
-- │<C-t>    │select_target            │Select a new target language.          │
-- │<M-s>    │switch_languages         │Switch source with target language.    │
-- │<M-t>    │translate                │Manually trigger translation.          │
-- 
-- 
-- │ Normal  │         Action          │              Description              │
-- │q        │close                    │Terminate current translation.         │
-- │<Esc>    │close                    │Terminate current translation.         │
-- │g?       │help                     │Show mappings in floating window.      │
-- │gy       │yank_close_translation   │Yank translation and quit.             │
-- │gY       │yank_close_input         │Yank input and quit.                   │
-- │gr       │replace_close_translation│Replace text with translation and quit.│
-- │gR       │replace_close_input      │Replace text with input and quit.      │
-- │ga       │append_close_translation │Append translation to text and quit.   │
-- │gA       │append_close_input       │Append input to text and quit.         │
-- │ge       │select_engine            │Select a new translation engine.       │
-- │gs       │select_source            │Select a new source language.          │
-- │gt       │select_target            │Select a new target language.          │
-- │gS       │switch_languages         │Switch source with target language.    │
-- │gT       │translate                │Manually trigger translation.          │
-- 
-- 
-- SELECT MODE                                              *pantran-select-mode*
-- 
-- │  Insert  │   Action    │                Description                 │
-- │<C-_>     │help         │Show mappings in floating window.           │
-- │<C-n>     │select_next  │Select next item in the list.               │
-- │<C-p>     │select_prev  │Select previous item in the list.           │
-- │<C-j>     │select_next  │Select next item in the list.               │
-- │<C-k>     │select_prev  │Select previous item in the list.           │
-- │<Down>    │select_next  │Select next item in the list.               │
-- │<Up>      │select_prev  │Select previous item in the list.           │
-- │<Cr>      │select_choose│Choose current item and exit selection mode.│
-- │<C-y>     │select_choose│Choose current item and exit selection mode.│
-- │<C-e>     │select_abort │Abort current selection.                    │
-- 
-- 
-- │  Normal  │   Action    │                Description                 │
-- │g?        │help         │Show mappings in floating window.           │
-- │j         │select_next  │Select next item in the list.               │
-- │k         │select_prev  │Select previous item in the list.           │
-- │<Down>    │select_next  │Select next item in the list.               │
-- │<Up>      │select_prev  │Select previous item in the list.           │
-- │gg        │select_first │Select first item in the list.              │
-- │G         │select_last  │Select last item in the list.               │
-- │<Cr>      │select_choose│Choose current item and exit selection mode.│
-- │<Esc>     │select_abort │Abort current selection.                    │
-- │q         │select_abort │Abort current selection.                    │
