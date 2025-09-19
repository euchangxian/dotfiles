return {
  {
    "neovim/nvim-lspconfig",
    keys = {
      { "<C-k>", mode = "i", false },
    },
    opts = {
      servers = {
        ocamllsp = {
          mason = false,
          cmd = { "ocamllsp" },
        },
      },
    },
  },
}
