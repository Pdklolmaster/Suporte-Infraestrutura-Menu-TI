# Windows Automation & Support Toolkit 🛠️⚡

Este repositório reúne um ecossistema de scripts e utilitários estruturados em **PowerShell** e **Batch**, projetados para automatizar tarefas de suporte técnico, rotinas de DevOps e processos de implementação de software em ambientes Windows.

O objetivo principal do toolkit é eliminar o trabalho manual repetitivo, mitigar falhas humanas em produção e acelerar o provisionamento e validação de ambientes.

## 🚀 Funcionalidades e Engenharia dos Scripts

As ferramentas estão divididas em módulos especializados para responder a desafios reais de infraestrutura e manipulação de dados[cite: 2]:

### 1. Automação de Ambientes e Snippets
* **`make_test_copy.ps1`**: Automatiza a criação de réplicas e cópias de segurança estruturadas para testes isolados[cite: 2].
* **`implant_snip.ps1` / `snippet_implant.ps1`**: Agiliza o deployment e a injeção automatizada de trechos de código ou configurações padronizadas em múltiplos ficheiros[cite: 2].

### 2. Integridade de Dados e Validação (Linter & Sanitize)
* **`resave_utf8.ps1`**: Varre e força a regravação de ficheiros para a codificação universal UTF-8, prevenindo quebras de leitura e erros de acentuação no sistema[cite: 2].
* **`check_quotes.ps1` e `count_braces.ps1`**: Scripts de validação sintática que inspecionam ficheiros de configuração para garantir o fecho correto de aspas e chaves[cite: 2].
* **`run_checks.ps1`**: Centralizador automatizado projetado para correr uma suite completa de testes e verificações de integridade de uma só vez[cite: 2].
* **`tokenize.ps1`**: Utilitário focado na análise estrutural e tokenização de strings ou ficheiros de dados[cite: 2].

### 3. Manipulação de Fluxos e Terminal
* **`print_lines.ps1`**: Filtra e imprime linhas selecionadas de logs extensos diretamente no terminal, otimizando a depuração[cite: 2].
* **`parse_menu.ps1`**: Engine de processamento e parsing para construção dinâmica das opções do menu[cite: 2].

## 🎮 Interfaces de Execução Unificadas

Para garantir flexibilidade operacional, o toolkit fornece duas portas de entrada interativas que mapeiam as ferramentas da pasta `tools/`[cite: 2]:
* **`MenuSuporte.ps1`**: Interface interativa moderna construída nativamente em PowerShell (v5 ou superior recomendado)[cite: 2].
* **`MenuSuporte.bat`**: Menu legado em Batch para execução rápida em ambientes CMD restritos ou prompts de recuperação do Windows[cite: 2].

## 📂 Arquitetura do Repositório

* `tools/`: Centraliza a lógica de todos os scripts utilitários em PowerShell[cite: 2].
* `Bin/Repositorio/`: Diretório local reservado para o armazenamento de binários externos e dependências[cite: 2].
* `ImagensISO/` e `ISO/`: Espaços de trabalho dedicados à coleta, extração e build de imagens de sistema customizadas[cite: 2].

