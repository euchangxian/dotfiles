return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      preset = "super-tab",
      ["<C-j>"] = { "select_next", "fallback" },
      ["<C-k>"] = { "select_prev", "fallback" },
      ["<Up>"] = { "select_next", "fallback" },
      ["Down"] = { "select_prev", "fallback" },
    },
    trigger = {
      completion = {
        keyword_range = "full",
      },
      signature_help = {
        enabled = true,
      },
    },
  },
}
