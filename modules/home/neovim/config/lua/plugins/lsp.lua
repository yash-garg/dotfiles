return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Inlay hints on attach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
          end
        end,
      })

      -- Server-specific overrides
      vim.lsp.config("ts_ls", {
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        settings = {
          javascript = {
            inlayHints = {
              includeInlayEnumMemberValueHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayVariableTypeHints = true,
            },
          },
          typescript = {
            inlayHints = {
              includeInlayEnumMemberValueHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayVariableTypeHints = true,
            },
          },
        },
      })

      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            diagnostics = {
              enable = true,
              styleLints = { enable = true },
            },
            files = { excludeDirs = { ".direnv/" } },
            procMacro = { enable = true },
          },
        },
      })

      -- Enable all servers (nvim-lspconfig provides defaults for these)
      vim.lsp.enable({
        "astro",
        "biome",
        "dartls",
        "docker_compose_language_service",
        "golangci_lint_ls",
        "gopls",
        "nixd",
        "ruff",
        "tailwindcss",
        "ts_ls",
        "yamlls",
      })
    end,
  },
}
