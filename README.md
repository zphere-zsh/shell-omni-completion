# Zsh Omni Completion for Vim

This Vim plugin implements a smart Vim omni completion for Bash and Zshell scripting
languages. The completion's characteristics are:

1. It'll detect all function-names declared inside `filetype=sh|bash|zsh` Vim
   buffers **and complete them only on the command-position**, i.e.: only as the
   first keyword in a line or following a command-separator like **|** (`fun1`
   **|** `fun2`, etc.), a semicolon **;**, etc.

2. It'll detect all parameter-names, i.e.: only keywords following a **$…**, and
   **complete them only after a $… or at the command-position** (to also
   complete the `PARAM=VALUE` assignment-commands).

3. It'll detect all arrays' and hashes' keys (i.e.: subscripts) **and complete
   them only after a PARAM[…** — i.e.: it'll complete array keys only when
   you'll be actually entering them.

# Installation and Usage

An auto-completion plugin
[**zphere-zsh/shell-auto-popmenu**](https://github.com/zphere-zsh/shell-auto-popmenu/)
is recommended (it's a plugin adapted specifically for this omni completion),
otherwise a regular omni-completion invocation via `Ctrl-X Ctrl-O` is also
possible.

Only sourcing of the plugin is required, no other setup is needed. You can use
your favourite Vim plugin manager or manually copy the script to the
`~/.vim/plugin/autoload` directory.

# Presentation

[![asciicast](https://asciinema.org/a/351814.svg)](https://asciinema.org/a/351814)

<!-- vim:set ft=markdown tw=80 fo+=a1n autoindent: -->
