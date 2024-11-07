return {
  "nvimdev/lspsaga.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local saga = require("lspsaga")

    saga.setup({
      hover = {
        open_link = "gx",
        open_browser = "open",
      },
      definition = {
        edit = "<C-c>o",
        vsplit = "<C-c>v",
        split = "<C-c>i",
        tabe = "<C-c>t",
        quit = "q",
      },
      finder = {
        max_height = 0.5,
        min_width = 30,
        force_max_height = false,
        keys = {
          jump_to = "p",
          expand_or_jump = "o",
          vsplit = "s",
          split = "i",
          tabe = "t",
          quit = { "q", "<ESC>" },
        },
      },
    })
  end,
}
