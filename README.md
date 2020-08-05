# Zsh Omni Completion for Vim

This Vim plugin implements a smart Vim omni completion for Zshell scripting
language.  The completion's characteristics are:

1. It'll detect all functions declared inside `filetype=zsh` Vim buffers **and
   complete them only on the command-position**, i.e.: only as the first keyword
   in a line or following a command-separator like **|** (`fun1 | fun2`, etc.),
   **;**, etc.

2. It'll detect all parameter-names, i.e.: only keywords following a **$…**, and
   **complete them only after a $… or at the command-position** (to also
   complete the `PARAM=VALUE` assignment-commands).

3. It'll detect all arrays' and hashes' keys (i.e.: subscripts) **and complete
   them only after a PARAM[…** — i.e.: it'll complete array keys only when
   you'll be actually entering them.

# Installation and Usage

An auto-completion plugin
[**zphere-zsh/zsh-auto-popmenu**](https://github.comzphere-zsh/zsh-auto-popmenu/)
is recommended (it's a plugin adapted specifically for the omni completion),
otherwise a regular omni-completion invocation via `Ctrl-X Ctrl-O` is also
possible.

<!-- vim:set ft=markdown tw=80 fo+=a1n autoindent: -->
