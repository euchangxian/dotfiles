return {
  "saghen/blink.cmp",
  dependencies = {
    "neovim/nvim-lspconfig",
  },
  opts = {
    keymap = {
      preset = "super-tab",
      ["<Tab>"] = {
        function(cmp)
          if cmp.is_in_snippet() then
            return cmp.accept()
          else
            return cmp.select_and_accept()
          end
        end,
        "snippet_forward",
        "fallback",
      },
      ["<C-j>"] = { "select_next", "fallback" },
      ["<C-k>"] = { "select_prev", "fallback" },
      ["<Up>"] = { "select_next", "fallback" },
      ["<Down>"] = { "select_prev", "fallback" },
    },
    trigger = {
      completion = {
        keyword_range = "full",
        show_in_snippet = false,
      },
      signature_help = {
        enabled = true,
      },
    },
  },
}
