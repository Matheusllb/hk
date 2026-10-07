# hk

Instalador do [harness-kit](https://github.com/Matheusllb/harness-kit) (privado). No PowerShell:

```powershell
irm https://matheusllb.github.io/hk/i.ps1 | iex
```

Instala o que faltar (Git, GitHub CLI, Node, Python, Windows Terminal, Claude Code, Graft), faz o
login no GitHub, aceita o convite pendente, baixa o kit e roda o instalador. Pode rodar de novo
para atualizar. Este repositório guarda só o `i.ps1`; o kit continua privado.

Sem convite: o mesmo comando. O script pede a **senha da equipe**, que o dono do kit passa em
particular, e com ela abre uma chave só de leitura do kit, que vai cifrada no próprio `i.ps1`. A chave fica
em `~/.harness-kit-segredos/`, só para o seu usuário, e as atualizações seguintes usam essa chave.
