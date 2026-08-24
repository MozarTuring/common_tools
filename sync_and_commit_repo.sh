cd $HOME/project/
repo_path="$1"
cd "$repo_path"
git show-ref --verify --quiet refs/heads/jingwei && echo "Branch jingwei already exists, skipping rename." || (git branch -m jingwei && echo "Branch renamed to jingwei")

while IFS= read -r pattern; do
    grep -qxF "$pattern" .gitignore 2>/dev/null || echo "$pattern" >>.gitignore
done <~/project/common_tools/common_gitignore.txt
git submodule foreach 'git add -A && (git commit -m "v" || true)'
git add -A >/dev/null
(
    _staged=$(git diff --cached --name-only)
    _non_config=$(echo "$_staged" | grep -v "^jwm_configs/" || true)
    if [[ -n "$_staged" && -n "$_non_config" ]]; then
        git commit -m "v" >/dev/null
        tmpbranch=$(git branch --show-current)
        if [[ ${tmpbranch} == "jingwei"* ]]; then
            git push origin -u ${tmpbranch} >/dev/null
        fi
    fi
)
export last_commit=$(git rev-parse HEAD)
export _git_branch=$(git -C ./ rev-parse --abbrev-ref HEAD 2>/dev/null)
if [[ -n "$server_name" ]]; then
    _remote_proj="${repo_path}_${_git_branch}"
    export run_dir_remote="${run_dir_home}/project_remote_jwm/${_remote_proj}"
    echo "remote dir: ${run_dir_remote}"
    rsync -a --no-links --exclude-from="$HOME/project/common_tools/rsync_exclude.txt" ./ "$server_name":${run_dir_remote}/
    tmppath="/Users/jinma63/Desktop/baidu/project_nogit/${repo_path}"
    if [[ ! -d ${tmppath} ]]; then
        mkdir -p ${tmppath}
    fi
    rsync -av --safe-links ${tmppath} "$server_name":${run_dir_remote}/jwm_configs/
    if [[ ! -L "./jwm_configs/${repo_path}" ]]; then
        ln -s ${tmppath} ./jwm_configs/${repo_path}
    fi

fi
