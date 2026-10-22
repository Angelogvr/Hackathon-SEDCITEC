#!/bin/sh
printf '\033c\033]0;%s\a' Novo Projeto de Jogo
base_path="$(dirname "$(realpath "$0")")"
"$base_path/linuxExecutavel.x86_64" "$@"
