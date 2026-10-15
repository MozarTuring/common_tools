# _retry_ssh <host> <cmd...>: run an ssh/rsync command; on exit code 255 (ssh connection failed)
# wait for the connection via wait_for_ssh.sh and retry, so connection errors never reach the ERR trap
_retry_ssh() {
    local _host=$1 _rc
    shift
    while true; do
        "$@" && return 0 || _rc=$?
        [[ ${_rc} -eq 255 ]] || return ${_rc}
        echo "ssh connection to ${_host} failed (exit code 255), waiting for ssh" >&2
        host=${_host}
        source "$(dirname "${BASH_SOURCE[0]}")/wait_for_ssh.sh" >&2
    done
}
