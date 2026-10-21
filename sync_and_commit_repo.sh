# Usage: sync_and_commit_repo.sh <repo>
# commits ~/project/<repo> (and pushes a pikaq* branch), then writes its branch to
# ~/project/zzzpkqoutput/<repo>/git_branch.txt, which meta_script.sh reads to rsync the repo to each run's server.
# Run once per batch (by the nvim batch, before its first run): the batch's runs overlap, and concurrent commits in
# one repo collide on git's index.lock.
set -eo pipefail
cd $HOME/project/
repo_path="$1"
branch_file="$HOME/project/zzzpkqoutput/${repo_path}/git_branch.txt"
mkdir -p "$(dirname "${branch_file}")"
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
_git_branch=$(git -C ./ rev-parse --abbrev-ref HEAD 2>/dev/null)
# written last: its presence tells the batch's other runs that the commit is done
echo "${_git_branch}" >"${branch_file}"
