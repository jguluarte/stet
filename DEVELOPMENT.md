# Development

`make setup` runs `scripts/install-prerequisites.sh`, a semi-guided script that
checks for each prerequisite and offers to install it. If you decline, it prints
the commands so you can install them yourself.

## Devbox

[Devbox](https://www.jetify.com/devbox) manages project-level dependencies (Go, tooling, etc.).

```bash
curl -fsSL https://get.jetify.com/devbox | bash
```

## Direnv

[direnv](https://direnv.net) auto un/loads the devbox environment when you `cd` in/out of the repo.

```bash
curl -sfL https://direnv.net/install.sh | bash
```

> [!NOTE]
> The setup script offers to add the direnv hook to `~/.zshrc`. If you skipped it:
>
> ```eval "$(direnv hook zsh)"```

Then run `direnv allow` from the repo root to activate the environment.

## Ollama

[Ollama](https://ollama.com) runs large language models locally. Stet uses it
for all inference.

> [!NOTE]
> The curl installer prompts for `sudo`.

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Start the server: `ollama serve`.

### Model

The default model is set in `.envrc` via `STET_MODEL` (currently
`qwen3-coder:30b`). The setup script pulls whichever model that variable
resolves to.

To use a different model, override it in `.envrc.local` (git-ignored):

```bash
export STET_MODEL="qwen2.5-coder:32b"
```
