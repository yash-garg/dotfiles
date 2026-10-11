# Neovim Keymaps

Leader key: <kbd>,</kbd>

---

## Navigation

| Key | Action |
|-----|--------|
| <kbd>s</kbd> + 2 chars | Flash jump anywhere on screen |
| <kbd>S</kbd> + 2 chars | Flash jump (treesitter node select) |
| <kbd>g</kbd><kbd>g</kbd> | Go to top of file |
| <kbd>G</kbd> | Go to bottom of file |
| <kbd>,</kbd><kbd>h</kbd> | Go to start of line |
| <kbd>,</kbd><kbd>l</kbd> | Go to end of line |
| <kbd>w</kbd> / <kbd>b</kbd> | Next / prev word |
| <kbd>e</kbd> | End of word |
| <kbd>Ctrl</kbd>+<kbd>d</kbd> | Scroll down half page |
| <kbd>Ctrl</kbd>+<kbd>u</kbd> | Scroll up half page |
| <kbd>Ctrl</kbd>+<kbd>f</kbd> | Scroll down full page |
| <kbd>Ctrl</kbd>+<kbd>b</kbd> | Scroll up full page |
| <kbd>{</kbd> / <kbd>}</kbd> | Jump between blank lines (paragraphs) |

---

## Editing

| Key | Action |
|-----|--------|
| <kbd>c</kbd><kbd>a</kbd><kbd>w</kbd> | Change around word (delete word + surrounding spaces, insert) |
| <kbd>d</kbd><kbd>a</kbd><kbd>w</kbd> | Delete around word (delete word + surrounding spaces) |
| <kbd>c</kbd><kbd>i</kbd><kbd>w</kbd> | Change inner word |
| <kbd>d</kbd><kbd>i</kbd><kbd>w</kbd> | Delete inner word |
| <kbd>c</kbd><kbd>i</kbd><kbd>"</kbd> | Change inside quotes |
| <kbd>c</kbd><kbd>a</kbd><kbd>"</kbd> | Change around quotes (includes quotes) |
| <kbd>d</kbd><kbd>i</kbd><kbd>(</kbd> | Delete inside parentheses |
| <kbd>c</kbd><kbd>c</kbd> | Change entire line |
| <kbd>d</kbd><kbd>d</kbd> | Delete entire line |
| <kbd>y</kbd><kbd>y</kbd> | Yank (copy) entire line |
| <kbd>Y</kbd> | Yank to end of line |
| <kbd>p</kbd> / <kbd>P</kbd> | Paste after / before |
| <kbd>u</kbd> | Undo |
| <kbd>Ctrl</kbd>+<kbd>r</kbd> | Redo |
| <kbd>></kbd><kbd>></kbd> / <kbd><</kbd><kbd><</kbd> | Indent / unindent line |
| <kbd>Tab</kbd> (visual) | Indent selection |
| <kbd>Shift</kbd>+<kbd>Tab</kbd> (visual) | Unindent selection |
| <kbd>g</kbd><kbd>c</kbd> + motion | Toggle comment |
| <kbd>g</kbd><kbd>c</kbd><kbd>c</kbd> | Toggle comment on line |

---

## Search

| Key | Action |
|-----|--------|
| <kbd>/</kbd> | Search forward |
| <kbd>?</kbd> | Search backward |
| <kbd>n</kbd> / <kbd>N</kbd> | Next / prev match |
| <kbd>Esc</kbd> | Clear search highlight |
| <kbd>Ctrl</kbd>+<kbd>f</kbd> | Fuzzy find in current buffer |
| <kbd>,</kbd><kbd>/</kbd> | Live grep across project |

---

## File Explorer

| Key | Action |
|-----|--------|
| <kbd>,</kbd><kbd>t</kbd> | Toggle NeoTree file explorer |

---

## Telescope

| Key | Action |
|-----|--------|
| <kbd>,</kbd><kbd>Space</kbd> | List open buffers |
| <kbd>,</kbd><kbd>p</kbd> | Search git files |
| <kbd>,</kbd><kbd>/</kbd> | Live grep (search in files) |
| <kbd>,</kbd><kbd>g</kbd><kbd>c</kbd> | Browse git commits |
| <kbd>,</kbd><kbd>g</kbd><kbd>s</kbd> | Git status |
| <kbd>,</kbd><kbd>f</kbd><kbd>e</kbd> | File browser |
| <kbd>,</kbd><kbd>w</kbd><kbd>d</kbd> | Workspace diagnostics |

---

## LSP

| Key | Action |
|-----|--------|
| <kbd>g</kbd><kbd>d</kbd> | Go to definition |
| <kbd>g</kbd><kbd>D</kbd> | Go to declaration |
| <kbd>g</kbd><kbd>r</kbd> | Go to references |
| <kbd>g</kbd><kbd>i</kbd> | Go to implementation |
| <kbd>K</kbd> | Hover documentation |
| <kbd>[</kbd><kbd>d</kbd> / <kbd>]</kbd><kbd>d</kbd> | Previous / next diagnostic |

---

## Diagnostics (Trouble)

| Key | Action |
|-----|--------|
| <kbd>,</kbd><kbd>x</kbd><kbd>x</kbd> | Toggle diagnostics panel (all files) |
| <kbd>,</kbd><kbd>x</kbd><kbd>b</kbd> | Toggle diagnostics for current buffer |
| <kbd>,</kbd><kbd>x</kbd><kbd>s</kbd> | Toggle symbols panel |
| <kbd>,</kbd><kbd>x</kbd><kbd>q</kbd> | Toggle quickfix list |

---

## Folds

| Key | Action |
|-----|--------|
| <kbd>z</kbd><kbd>a</kbd> | Toggle fold under cursor |
| <kbd>z</kbd><kbd>R</kbd> | Open all folds |
| <kbd>z</kbd><kbd>M</kbd> | Close all folds |
| <kbd>z</kbd><kbd>o</kbd> / <kbd>z</kbd><kbd>c</kbd> | Open / close fold |

---

## Splits

| Key | Action |
|-----|--------|
| `:vs` | Vertical split |
| `:sp` | Horizontal split |
| <kbd>Ctrl</kbd>+<kbd>h</kbd>/<kbd>j</kbd>/<kbd>k</kbd>/<kbd>l</kbd> | Navigate between splits (tmux-aware) |
