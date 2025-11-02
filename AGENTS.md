# AGENTS.md

This file provides guidance to AI assistants when working with code in this repository.

## Overview

This is an Ansible-based provisioning system for setting up macOS development environments. The repository automates the installation and configuration of development tools, applications, and system settings across multiple machines (iMac, MacBook Pro, Mac Mini, etc.).

## Architecture

### Playbook Structure

The system uses **machine-specific playbooks** (e.g., `ohmymbp.yml`, `ohmyimac.yml`, `ohmytnmbp.yml`, `ohmymini.yml`) that compose different roles based on what each machine needs. Each playbook:
- Targets `localhost` for local provisioning
- Sets Homebrew environment variables for security (`HOMEBREW_NO_INSECURE_REDIRECT`, `HOMEBREW_CASK_OPTS: "--require-sha"`)
- Includes a curated list of roles (many commented out by default)

### Role Organization

There are ~62 roles in the `roles/` directory, organized by purpose:

**Core Infrastructure Roles:**
- `shell-config` - Creates `~/.bash_profile` and `~/.paths_homes_etc`, detects shell type (bash/zsh/ksh), sets locale
- `perfectly_brewed` - Configures Homebrew environment variables and GitHub API token
- `zshell` - Z shell configuration
- `git-mods` - Git customizations

**Development Environment Roles:**
- Language-specific: `java-development`, `python-development`, `js-development`, `golang-development`, `kotlin-development`, `scala-development`, `clojure-development`, `ruby-development`, `elm-development`, `dotnet-development`, `groovy-development`, `r-development`
- Infrastructure: `dockered`, `kubernetes`, `cloudy`
- Specialized: `app-engine-development`, `android-development`, `machine-learning`

**Tools & Applications:**
- `cli-tools` - Common CLI utilities (tree, wget, autojump, ag/ripgrep, bat, fzf, httpie, jq, yq, gh, thefuck, tldr, tmux)
- `artificial_intelligence` - AI tools (ChatGPT, Claude, Claude Code, GitHub Copilot CLI, codex)
- `os-tools`, `os-adjustments` - System-level utilities and tweaks
- `browsers_and_tweaks` - Web browsers and extensions
- `productivity`, `collaborative`, `knowledge` - Productivity applications
- `fonts`, `a_more_usable_ui` - UI/UX improvements

**Other Categories:**
- Database: `my-sequel`, `postgresql-y`
- Editors: `idea`, `sublime`, `emacs`, `atomic`
- Special purpose: `smarthouse` (OpenHAB home automation), `remoting`, `screencasting`, `app-store-apps`, `spotify`

### Key Configuration Files

- `ansible.cfg` - Uses `hosts` inventory, vault password from `~/.vault_pass`, Python 3 interpreter, selective stdout callback
- `requirements.yml` - Ansible Galaxy dependencies (currently just `community.general` collection)
- `group_vars/all.yml` - Global variable for Python 3 interpreter
- `hosts` - Inventory file for localhost

### Shell Configuration Pattern

The system uses a centralized shell configuration approach:
1. Creates `~/.bash_profile` (if not exists)
2. Creates `~/.paths_homes_etc` (if not exists)
3. Sources `~/.paths_homes_etc` from `~/.bash_profile`
4. All roles add configuration to `~/.paths_homes_etc` using `blockinfile` or `lineinfile`
5. Shell detection code at the top sets `$PROFILE_SHELL` variable

This allows consistent configuration across bash, zsh, and other Bourne-compatible shells.

## Common Commands

### Initial Setup (One-time)

Bootstrap a new macOS machine:
```bash
cd .provisioning
./bootstrap.sh
```

This installs Xcode command-line tools, Homebrew, Ansible, and required Galaxy collections.

### Running Playbooks

After changes to `requirements.yml`:
```bash
ansible-galaxy install -r requirements.yml --force
```

Run a machine-specific playbook:
```bash
# From the .provisioning directory
ansible-playbook -Kv ohmymbp.yml

# Or using the suggested symlink approach:
ln -s `pwd`/.provisioning ~/.provisioning
pushd ~/.provisioning/ && ansible-playbook -Kv ohmymbp.yml ; popd
```

The `-K` flag prompts for sudo password (needed for some system modifications).
The `-v` flag enables verbose output.

### Testing and Validation

Before committing changes:
```bash
# Check YAML syntax
ansible-playbook ohmymbp.yml --syntax-check

# Dry run with diff to preview changes
ansible-playbook -Kv ohmymbp.yml --check --diff

# Run specific roles or tags
ansible-playbook -Kv ohmymbp.yml --tags "tag_name"
ansible-playbook -Kv ohmymbp.yml --start-at-task "task name"
```

Playbooks should be **idempotent** - running them a second time on the same system should report zero changes.

### Vault Usage

Sensitive variables (like `github_api_token` in `perfectly_brewed` role) use Ansible Vault:
```bash
# Encrypt sensitive files
ansible-vault encrypt group_vars/<scope>.yml

# Password should be in ~/.vault_pass (configured in ansible.cfg)
```

## Development Workflow

### Adding a New Role

1. Create role directory: `mkdir -p roles/new-role-name/tasks`
2. Create `roles/new-role-name/tasks/main.yml` with tasks
3. Add role variables to `roles/new-role-name/vars/main.yml` if needed
4. Optionally add `files/` or `templates/` directories for static files or Jinja2 templates
5. Add the role to appropriate playbook(s) (e.g., `ohmymbp.yml`)
6. Test with `ansible-playbook -Kv playbook.yml --check --diff`

**Role naming:** Use lowercase words separated by hyphens or underscores to match existing conventions.

### Modifying Existing Roles

- Role tasks are in `roles/*/tasks/main.yml`
- Variables are in `roles/*/vars/main.yml`
- Use explicit Ansible modules (`package`, `lineinfile`, `blockinfile`, etc.) rather than shell commands
- Use `ansible.builtin` modules or community modules from `community.general`
- Roles assume macOS; OS conditionals are no longer required
- Keep shell scripts POSIX `sh` compatible; guard with `creates:` or conditionals for idempotency

### Homebrew Package Installation Pattern

```yaml
- name: install packages
  homebrew:
    name:
      - package1
      - package2
```

For cask applications:
```yaml
- name: install applications
  homebrew_cask:
    name:
      - app-name
```

### Shell Configuration Pattern

Add configuration to user's shell:
```yaml
- name: configure something
  blockinfile:
    dest: "{{ ansible_env.HOME }}/.paths_homes_etc"
    insertafter: EOF
    marker: "# {mark} ANSIBLE MANAGED BLOCK for feature-name"
    content: |
             export VARIABLE=value
             alias foo='bar'
```

## Coding Style Conventions

- Use **YAML with two-space indentation**
- Write task names in **sentence case** with human-friendly descriptions (e.g., "Install common CLI tools")
- Use explicit module names rather than shell commands when possible
- Keep shell scripts POSIX `sh` compatible for portability
- Ensure idempotency - tasks should be safe to run multiple times

## Commit Guidelines

Follow the existing commit history style:
- Use **short, imperative commit subjects** (e.g., "Add uv", "Fix gw() for bash")
- Group related file updates in a single commit
- Recent commits show the pattern: descriptive but concise

## Important Notes

- The system now targets **macOS (Darwin)** exclusively; Linux support has been removed
- **Inventory defaults to localhost** - all provisioning is local execution
- Vault-encrypted variables require `~/.vault_pass` file (configured in `ansible.cfg`)
- The `artificial_intelligence` role adds `.claude/`, `.serena/`, `CLAUDE.md`, and `AGENTS.md` to global gitignore
- Commented-out roles in playbooks indicate optional features that can be enabled per machine
- Some roles like `smarthouse` have hardware dependencies (Z-Wave USB stick with specific drivers)
