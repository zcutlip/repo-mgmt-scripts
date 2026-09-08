# Agent Instructions

## What This Repo Is
- POSIX `sh` scripts in `src/` that manage branches, tags, and PyPI releases for a *target Python project*.
- Scripts operate on the target project's CWD, locating its `pyproject.toml`, `setup.py`, and `<pkg>/__about__.py`.
- Consumed by target projects as a git submodule (see `README.md`) or via `./install <dir>`, which symlinks `src/` scripts into the target and copies `src/example_project_settings.sh` → `project_settings.sh`.

## File Naming Policy (enforced by pre-commit)
- Executable commands get NO `.sh` extension: `src/deletebranch`, `src/tag`, `src/release`, `src/gc_about`, `src/gc_changelog`, `install`.
- Non-executable sourced libraries get `.sh`: `src/functions.sh`, `src/example_project_settings.sh`.
- New scripts must follow this or `script-must-have-extension` / `script-must-not-have-extension` hooks will fail.

## Shell Rules
- POSIX `sh` only (`shell=sh` in `.shellcheckrc`): no bashisms — no `local`, `[[ ]]`, or arrays.
- Private variables are prefixed with `_` and `unset` after use in place of `local` (see `src/functions.sh`).
- Shared helpers belong in `src/functions.sh`; entry scripts source it as `. "$DIRNAME"/functions.sh` with `DIRNAME="$(dirname "$0")"`.
- Exit through the `quit` helper (message + code), not bare `exit`.

## Verification
- No test suite and no CI. Verify with `pre-commit run --all-files` (shellcheck, YAML/JSON checks, extension policy).

## Config Resolution (`src/functions.sh`)
- `project_settings.sh` is sourced from the script's own directory (`$DIRNAME`) — i.e., next to the installed copies in the target project — never from CWD. Template: `src/example_project_settings.sh`.
- Distribution name: `$DISTRIBUTION_NAME` → `pyproject.toml` `[project].name` (stdlib `tomllib`) → `python3 setup.py --name`.
- Version: `<pkg>/__about__.py` via `src/read_about_version.py` (AST parse — never imports the package or its deps) → `python3 setup.py --version`.
- `ROOT_PACKAGE_NAME` overrides the package directory name when it differs from the distribution name (e.g., `mock-op` → `mock_op`).
- `src/release` skips PyPI upload unless `TWINE_UPLOAD_ENABLED` is unset or `"1"`; the shipped template defaults it to `"0"`.
- Git tags are `v<version>`.

## Misc
- Root `projectname.sh` is a gitignored local fixture — never commit or reference it.
- Set the executable bit to match the naming policy when adding scripts.
- Commit messages: lowercase imperative (e.g., "add install script").
