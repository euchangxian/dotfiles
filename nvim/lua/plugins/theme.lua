return {
  -- {
  --   "folke/tokyonight.nvim",
  -- },
  -- {
  --   "LazyVim/LazyVim",
  --   opts = {
  --     style = "moon",
  --   },
  -- },

  {
    "philosofonusus/morta.nvim",
    name = "morta",
    priority = 1000,
    opts = {},
    config = function()
      vim.cmd.colorscheme("morta")
    end,
  },
}
