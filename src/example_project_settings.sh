# shellcheck disable=SC2034
# if this is used it should be copied to the project's directory next to
# the symlinks/copies of these repo management scripts, and renamed to project_settings.sh
# e.g., project/scripts/project_settings.sh

# resolution order for the distribution name is:
# DISTRIBUTION_NAME, then static [project] name from pyproject.toml,
# then `python3 ./setup.py --name`. Set DISTRIBUTION_NAME only when those
# produce the wrong PyPI distribution name
# DISTRIBUTION_NAME="repo-mgmt-scripts"

# version resolution prefers <package>/__about__.py (via stdlib ast),
# falling back to `python3 ./setup.py --version`.
# for python projects, if the root package is named differently
# than the project/distribution name, override that here
# e.g., mock-op vs mock_op
# This will get used for scripts that try to locate files *within* the project
# e.g., mock_op/__about__.py
# ROOT_PACKAGE_NAME="repo_mgmt_scripts"

# Either don't set, or set to "1" to enable
# if set at all and not set to "1" twine upload will not happen
TWINE_UPLOAD_ENABLED="0"
