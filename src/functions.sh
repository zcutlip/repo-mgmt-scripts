# In shell, success is exit(0), error is anything else, e.g., exit(1)
SUCCESS=0
FAILURE=1

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
    _version="$(python3 ./setup.py --version)" || quit "Unable to detect package version" $?
    printf "%s" "$_version"
}

version_is_tagged(){
    _version="$1"
    # e.g., verion = 0.1.0
    # check if git tag -l v0.1.0 exists
    tag_description=$(git tag -l v"$_version")
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
