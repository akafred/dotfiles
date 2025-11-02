# Development guidelines – Commits

## Commit Message Style

This project uses **simple, descriptive commit messages** without prefixes or notation systems.

### Format

```
Short description of the change
```

- Use imperative mood ("Add", "Fix", "Remove", "Update")
- Keep the subject line under 55 characters
- Start with capital letter
- No period at the end
- Both English and Norwegian are acceptable
- One logical change per commit

### Examples from this project

```
Add uv
Fix gw() for bash
Remove files and tasks for non-Darwin systems
Add role for git-chain setup
Update git-chain to run `make install` only if repo is changed
Fix naming of copilot cli
Comment out displaylink temporarily
Allow failing unquarantine
Legg til mkcert mm
Fjern produktivitet
```

### Common patterns

**Adding features/files:**
```
Add <feature/tool/role>
Legg til <feature/tool/role>
```

**Fixing issues:**
```
Fix <specific issue>
```

**Removing code:**
```
Remove <what was removed>
Fjern <what was removed>
```

**Updating configuration:**
```
Update <what was updated>
```

**Adjustments:**
```
Adjust <what was adjusted>
```

### Guidelines

- Keep commits small and focused on one logical change
- Be descriptive but concise
- Use either English or Norwegian consistently within a commit
- No need for prefixes, tags, or risk markers
- Make the intent clear from the description alone