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

  -- {
  --   "philosofonusus/morta.nvim",
  --   name = "morta",
  --   priority = 1000,
  --   opts = {},
  --   config = function()
  --     vim.cmd.colorscheme("morta")
  --   end,
  -- },
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true,
      -- italic_comments = true,
      hide_fillchars = true,
    },
    config = function(_, opts)
      require("cyberdream").setup(opts)
      vim.cmd.colorscheme("cyberdream")
    end,
  },
}
