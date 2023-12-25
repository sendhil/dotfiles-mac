" Treesitter Config
lua << EOF
  require'nvim-treesitter.configs'.setup {
    ensure_installed = { "c", "lua", "rust", "go", "python" },
    highlight = {
      enable = true,              -- false will disable the whole extension
      additional_vim_regex_highlighting = false,
    },
    rainbow = {
      enable = true,
      -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
      extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
      max_file_lines = nil, -- Do not enable for files with more than n lines, int
      -- colors = {}, -- table of hex strings
      -- termcolors = {} -- table of colour name strings
    },
    textobjects = {
      select = {
        enable = true,

        -- Automatically jump forward to textobj, similar to targets.vim
        lookahead = true,

        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ["am"] = "@function.outer",
          ["im"] = "@function.inner",
          ["al"] = "@class.outer",
          -- You can optionally set descriptions to the mappings (used in the desc parameter of
          -- nvim_buf_set_keymap) which plugins like which-key display
          ["il"] = { query = "@class.inner", desc = "Select inner part of a class region" },
          ["ab"] = "@block.outer",
          ["ib"] = "@block.inner",
          ["ad"] = "@conditional.outer",
          ["id"] = "@conditional.inner",
          ["ao"] = "@loop.outer",
          ["io"] = "@loop.inner",
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
          ["af"] = "@call.outer",
          ["if"] = "@call.inner",
          ["ac"] = "@comment.outer",
          ["at"] = "@attribute.outer",
          ["it"] = "@attribute.inner",
          ["as"] = "@statement.outer",
          ["is"] = "@statement.outer",
        },
        -- You can choose the select mode (default is charwise 'v')
        --
        -- Can also be a function which gets passed a table with the keys
        -- * query_string: eg '@function.inner'
        -- * method: eg 'v' or 'o'
        -- and should return the mode ('v', 'V', or '<c-v>') or a table
        -- mapping query_strings to modes.
        -- selection_modes = treesitter_selection_mode,
        -- if you set this to `true` (default is `false`) then any textobject is
        -- extended to include preceding or succeeding whitespace. succeeding
        -- whitespace has priority in order to act similarly to eg the built-in
        -- `ap`.
        --
        -- can also be a function which gets passed a table with the keys
        -- * query_string: eg '@function.inner'
        -- * selection_mode: eg 'v'
        -- and should return true of false
        include_surrounding_whitespace = false,
      },
      lsp_interop = {
        enable = true,
        border = 'none',
        floating_preview_opts = {},
        peek_definition_code = {
          ["<leader>df"] = "@function.outer",
          ["<leader>dF"] = "@class.outer",
        },
      },
      swap = {
        enable = true,
        swap_next = {
          [")m"] = "@function.outer",
          [")c"] = "@comment.outer",
          [")a"] = "@parameter.inner",
          [")b"] = "@block.outer",
          [")C"] = "@class.outer",
        },
        swap_previous = {
          ["(m"] = "@function.outer",
          ["(c"] = "@comment.outer",
          ["(a"] = "@parameter.inner",
          ["(b"] = "@block.outer",
          ["(C"] = "@class.outer",
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          ["]m"] = "@function.outer",
          ["]f"] = "@call.outer",
          ["]d"] = "@conditional.outer",
          ["]o"] = "@loop.outer",
          ["]s"] = "@statement.outer",
          ["]a"] = "@parameter.outer",
          ["]c"] = "@comment.outer",
          ["]b"] = "@block.outer",
          ["]l"] = { query = "@class.outer", desc = "next class start" },
          ["]t"] = "@attribute.outer",
          ["]]m"] = "@function.inner",
          ["]]f"] = "@call.inner",
          ["]]d"] = "@conditional.inner",
          ["]]o"] = "@loop.inner",
          ["]]a"] = "@parameter.inner",
          ["]]b"] = "@block.inner",
          ["]]l"] = { query = "@class.inner", desc = "next class start" },
          ["]]t"] = "@attribute.inner",
        },
        goto_next_end = {
          ["]M"] = "@function.outer",
          ["]F"] = "@call.outer",
          ["]D"] = "@conditional.outer",
          ["]O"] = "@loop.outer",
          ["]S"] = "@statement.outer",
          ["]A"] = "@parameter.outer",
          ["]C"] = "@comment.outer",
          ["]B"] = "@block.outer",
          ["]L"] = "@class.outer",
          ["]T"] = "@attribute.outer",
          ["]]M"] = "@function.inner",
          ["]]F"] = "@call.inner",
          ["]]D"] = "@conditional.inner",
          ["]]O"] = "@loop.inner",
          ["]]A"] = "@parameter.inner",
          ["]]B"] = "@block.inner",
          ["]]L"] = "@class.inner",
          ["]]T"] = "@attribute.inner",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
          ["[f"] = "@call.outer",
          ["[d"] = "@conditional.outer",
          ["[o"] = "@loop.outer",
          ["[s"] = "@statement.outer",
          ["[a"] = "@parameter.outer",
          ["[c"] = "@comment.outer",
          ["[b"] = "@block.outer",
          ["[l"] = "@class.outer",
          ["[t"] = "@attribute.outer",
          ["[[m"] = "@function.inner",
          ["[[f"] = "@call.inner",
          ["[[d"] = "@conditional.inner",
          ["[[o"] = "@loop.inner",
          ["[[a"] = "@parameter.inner",
          ["[[b"] = "@block.inner",
          ["[[l"] = "@class.inner",
          ["[[t"] = "@attribute.inner",
        },
        goto_previous_end = {
          ["[M"] = "@function.outer",
          ["[F"] = "@call.outer",
          ["[D"] = "@conditional.outer",
          ["[O"] = "@loop.outer",
          ["[S"] = "@statement.outer",
          ["[A"] = "@parameter.outer",
          ["[C"] = "@comment.outer",
          ["[B"] = "@block.outer",
          ["[L"] = "@class.outer",
          ["[T"] = "@attribute.outer",
          ["[[M"] = "@function.inner",
          ["[[F"] = "@call.inner",
          ["[[D"] = "@conditional.inner",
          ["[[O"] = "@loop.inner",
          ["[[A"] = "@parameter.inner",
          ["[[B"] = "@block.inner",
          ["[[L"] = "@class.inner",
          ["[[T"] = "@attribute.inner",
        },
      },
  }
}

local ts_repeat_move = require "nvim-treesitter.textobjects.repeatable_move"

-- Repeat movement with ; and ,
-- ensure ; goes forward and , goes backward regardless of the last direction
-- vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
-- vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)

-- vim way: ; goes to the direction you were moving.
vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

  -- require("ibl").setup{}
require("ibl").setup {
    indent = { char = "|" },
    exclude = {
      buftypes = { "terminal" },
    },
    scope = {
      enabled = false,
    },
}

  require'treesitter-context'.setup{
      enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
  }

  require("bufferline").setup{
    options = {
      mode = "tabs",
      diagnostics = "nvim_lsp",
      separator_style = "slant",
      offsets = {{filetype = "NvimTree", text = "File Explorer"}},
      diagnostics_indicator = function(count, level, diagnostics_dict, context)
        local s = " "
        for e, n in pairs(diagnostics_dict) do
          local sym = e == "error" and " "
            or (e == "warning" and " " or "" )
          s = s .. n .. sym
        end
        return s
      end,
    }
  }

  require("toggleterm").setup{
    open_mapping = [[<c-\>]],
    shade_terminals = false,
  }

  function _G.set_terminal_keymaps()
    local opts = {noremap = true}
    vim.api.nvim_buf_set_keymap(0, 't', '<esc>', [[<C-\><C-n>]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', 'jk', [[<C-\><C-n>]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', '<C-h>', [[<C-\><C-n><C-W>h]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', '<C-j>', [[<C-\><C-n><C-W>j]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', '<C-k>', [[<C-\><C-n><C-W>k]], opts)
    vim.api.nvim_buf_set_keymap(0, 't', '<C-l>', [[<C-\><C-n><C-W>l]], opts)
  end

  -- if you only want these mappings for toggle term use term://*toggleterm#* instead
  vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

  require("which-key").setup {
  }

  require('fidget').setup{}

  require('lsp_signature').setup(cfg)
  vim.notify = require("notify")

  require('todo-comments').setup{}

  require('telescope').load_extension('file_browser')
  require('telescope').load_extension('fzf')
  require('telescope').load_extension('ui-select')

  require('leap').add_default_mappings()
  require('zen-mode').setup({
    plugins = {
      twilight = { enabled = false },
    }
  })

local wilder = require('wilder')
wilder.setup({modes = {':', '?'}})

wilder.set_option('renderer', wilder.popupmenu_renderer({
  highlighter = wilder.basic_highlighter(),
  left = {' ', wilder.popupmenu_devicons()},
  right = {' ', wilder.popupmenu_scrollbar()},
}))

require("winshift").setup({})

-- nvim-ufo setup

vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
vim.keymap.set('n', '<space>', 'za')
require('lsp-format').setup()

require('ufo').setup({
    provider_selector = function(bufnr, filetype, buftype)
        return {'treesitter', 'indent'}
    end
})

require('toggle_lsp_diagnostics').init()

EOF

let g:vista_default_executive = 'nvim_lsp'

source $HOME/.nvim/lsp.vimrc

" Ctrl-Space
if executable("rg")
  let g:CtrlSpaceGlobCommand = 'rg --smart-case --hidden --follow --no-heading --files'
endif 
let g:CtrlSpaceUseTabline = 0


