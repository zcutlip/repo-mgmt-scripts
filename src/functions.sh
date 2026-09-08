# In shell, success is exit(0), error is anything else, e.g., exit(1)
SUCCESS=0
FAILURE=1

if [ -z "$DIRNAME" ];
then
    DIRNAME="$(dirname "$0")"
fi

if [ -f "$DIRNAME/project_settings.sh" ];
then
    # shellcheck disable=SC1091
    . "$DIRNAME/project_settings.sh"
fi

project_name(){
    # resolution order:
    # 1. DISTRIBUTION_NAME set in project_settings.sh (explicit override)
    # 2. static [project] name from pyproject.toml (stdlib tomllib, no setuptools)
    # 3. legacy `python3 setup.py --name` fallback
    _name=""
    if [ -n "$DISTRIBUTION_NAME" ];
    then
        _name="$DISTRIBUTION_NAME"
    elif [ -f "pyproject.toml" ];
    then
        _name="$(python3 -c 'import tomllib; print(tomllib.load(open("pyproject.toml", "rb")).get("project", {}).get("name", ""))' 2>/dev/null)"
    fi
    if [ -z "$_name" ];
    then
        # DISTRIBUTION_NAME and pyproject.toml both failed to set the name. fall back to
        # legacy setup.py
        _name="$(python3 setup.py --name)" || quit "Can't determine project name" 1
    fi
    echo "$_name"
    unset _name
}

quit(){
    if [ $# -gt 1 ];
    then
        echo "$1"
        shift
    fi
    exit "$1"

}

git_current_branch () {
	_ref=$(git symbolic-ref --quiet HEAD 2> /dev/null)
	_ret=$?
	if [ $_ret != 0 ]
	then
		[ $_ret = 128 ] && return
		_ref=$(git rev-parse --short HEAD 2> /dev/null)  || return
	fi
	echo "${_ref#refs/heads/}"
}

branch_is(){
    _expected_branch="$1"
    _branch=$(git_current_branch)
    if [ "$_branch" = "$_expected_branch" ];
    then
        return $SUCCESS;
    else
        return $FAILURE;
    fi
}

branch_is_master_or_main(){
    if branch_is "master" || branch_is "main";
    then
        return $SUCCESS;
    else
        return $FAILURE;
    fi
}

branch_is_clean(){
    _modified=$(git ls-files -m) || quit "Unable to check for modified files." $?
    if [ -z "$_modified" ];
    then
        return $SUCCESS;
    else
        return $FAILURE;
    fi
}

current_version() {
    # resolution order:
    # 1. <package>/__about__.py __version__ via stdlib ast (no import, no
    #    setuptools). Package dir is ROOT_PACKAGE_NAME when set, else the
    #    distribution name with dashes mapped to underscores.
    # 2. legacy `python3 ./setup.py --version` fallback.
    _pkg="$ROOT_PACKAGE_NAME"
    if [ -z "$_pkg" ];
    then
        _pkg="$(project_name | tr '-' '_')" || quit "Can't determine project name" $?
    fi
    if [ -f "$_pkg/__about__.py" ];
    then
        _version="$(python3 "$DIRNAME/read_about_version.py" "$_pkg/__about__.py")" || quit "Unable to read version from $_pkg/__about__.py" $?
    else
        _version="$(python3 ./setup.py --version)" || quit "Unable to detect package version" $?
    fi
    printf "%s" "$_version"
    unset _pkg _version
}

version_is_tagged(){
    _version="$1"
    # e.g., verion = 0.1.0
    # check if git tag -l v0.1.0 exists
    tag_description=$(git --no-pager tag -l v"$_version")
    if [ -n "$tag_description" ];
    then
        return $SUCCESS;
    else
        return $FAILURE;
    fi
}

prompt_yes_no(){

    prompt_string="[Y/n]"
    if [ -n "$1" ];
    then
        prompt_string="$1 $prompt_string";
    fi
    echo "$prompt_string"
    read -r response

    case $response in
    [yY][eE][sS]|[yY])
        return $SUCCESS
        ;;
        *)
        return $FAILURE
        ;;
    esac
}
