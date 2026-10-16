set -eo pipefail
cd $HOME/project/
repo_path="$1"
cd "$repo_path"
git show-ref --verify --quiet refs/heads/pikaq && echo "Branch pikaq already exists, skipping rename." || (git branch -m pikaq && echo "Branch renamed to pikaq")

while IFS= read -r pattern; do
    grep -qxF "$pattern" .gitignore 2>/dev/null || echo "$pattern" >>.gitignore
done <~/project/common_tools/common_gitignore.txt
git submodule foreach 'git add -A && (git commit -m "v" || true)'
git add -A >/dev/null
(
    _staged=$(git diff --cached --name-only)
    _non_config=$(echo "$_staged" | grep -v "^pkq_configs/" || true)
    if [[ -n "$_staged" && -n "$_non_config" ]]; then
        git commit -m "v" >/dev/null
        tmpbranch=$(git branch --show-current)
        if [[ ${tmpbranch} == "pikaq"* ]]; then
            git push origin -u ${tmpbranch} >/dev/null
        fi
    fi
)
last_commit=$(git rev-parse HEAD)
export last_commit
_git_branch=$(git -C ./ rev-parse --abbrev-ref HEAD 2>/dev/null)
export _git_branch
if [[ -n "$PKQ_SERVER_NAME" ]]; then
    _remote_proj="${repo_path}_${_git_branch}"
    export run_dir_remote="${run_dir_home}/project_remote_pkq/${_remote_proj}"
    echo "remote dir: ${run_dir_remote}"
    rsync -rlt --no-links --delete --exclude-from="$HOME/project/common_tools/rsync_exclude.txt" ./ "$PKQ_SERVER_NAME":${run_dir_remote}/
    tmppath="/Users/jinma63/Desktop/baidu/project_nogit/${repo_path}/useful_on_remote"
    if [[ ! -d ${tmppath} ]]; then
        mkdir -p ${tmppath}
    fi
    if [[ ! -L "./pkq_configs/docs" ]]; then
        ln -sfn ${tmppath}/.. ./pkq_configs/docs
    fi
    rsync -av --safe-links ${tmppath}/ "$PKQ_SERVER_NAME":${run_dir_remote}/../project_nogit/useful_on_remote/
else
    echo "no server name"
    exit
fi
