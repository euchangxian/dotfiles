return {
  "mistricky/codesnap.nvim",
  build = "make build_generator",
  keys = {
    { "<leader>cp", "<cmd>CodeSnap<cr>", mode = "x", desc = "Save selected code snapshot into clipboard" },
    { "<leader>cP", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "Save selected code snapshot in ~/Downloads" },
  },
  opts = {
    mac_window_bar = true,
    watermark = "euchangxian",

    has_breadcrumbs = true,
    show_workspace = true,

    has_line_number = true,
    code_font_family = "MesloLGS NF",

    bg_theme = "grape",
    bg_x_padding = 20,
    bg_y_padding = 10,

    save_path = "~/Downloads",
  },
}
