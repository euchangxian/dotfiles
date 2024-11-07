return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    view = {
      adaptive_size = true,
    },
    window = {
      width = 25,
    },
    filesystem = {
      filtered_items = {
        visible = true,
        show_hidden_count = true,
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_by_name = {
          ".git",
          ".DS_Store",
        },
        never_show = {},
      },
    },
  },
}
