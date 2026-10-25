#!/usr/bin/env bash
# El sprite de Zoroark lo muestra fastfetch al arrancar zsh (ver ~/.zshrc)
cd "$HOME" || exit 1
exec "${SHELL:-/bin/bash}" -l
