# Suporte

Projeto de scripts e utilitários para suporte e implantação.

## Sobre

Este repositório agrupa scripts em lote e PowerShell usados para criar cópias de teste, validar arquivos, gerar ISOs e manter snippets.

## Estrutura

- `MenuSuporte.bat` — menu principal em batch
- `MenuSuporte.ps1` — menu principal em PowerShell
- `Bin/Repositorio/` — binários e repositório
- `ImagensISO/` — imagens ISO coletadas
- `ISO/` — ISOs processadas
- `tools/` — scripts utilitários (PowerShell)

Exemplos de scripts em `tools/`:

- `check_quotes.ps1` — valida aspas
- `count_braces.ps1` — conta chaves
- `implant_snip.ps1` — implanta snippets
- `make_test_copy.ps1` — cria cópias de teste
- `parse_menu.ps1` — parse de menus
- `print_lines.ps1` — imprime linhas selecionadas
- `resave_utf8.ps1` — regrava arquivos em UTF-8
- `run_checks.ps1` — executa verificações
- `snippet_implant.ps1` — implanta snippets (variante)
- `tokenize.ps1` — tokenizador

## Requisitos

- Windows
- PowerShell (v5+ recomendado)

## Como usar

1. Abra um terminal PowerShell na raiz do projeto.
2. Para iniciar o menu em PowerShell, execute:

```
.\MenuSuporte.ps1
```

3. Ou use o menu em lote no CMD/PowerShell:

```
MenuSuporte.bat
```

4. Para rodar scripts individuais, execute-os a partir da pasta `tools`:

```
.\tools\make_test_copy.ps1
```

## Contribuição

Abra uma issue para discutir mudanças ou envie um pull request com pequenas alterações e descrições claras.

## Licença

Sem licença especificada. Adicione um arquivo `LICENSE` se desejar aplicar uma licença.

---
Gerado automaticamente em 2026-06-02.
