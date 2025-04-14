return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    lazygit = {
      -- your lazygit configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      config_path = os.getenv("HOME") .. "/.config/lazygit/config.yml",
    },
  },
}
