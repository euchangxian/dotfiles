return {
  {
    "neovim/nvim-lspconfig",
    keys = {
      { "<C-k>", mode = "i", false },
    },
    opts = {
      diagnostics = {
        virtual_text = false,
      },
      servers = {
        ocamllsp = {
          mason = false,
          cmd = { "ocamllsp" },
        },
      },
    },
  },
}
