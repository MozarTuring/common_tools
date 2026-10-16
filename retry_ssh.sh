_clear_stale_control_socket() {
    local host=$1 ctl_path
    ctl_path=$(ssh -G "$host" 2>/dev/null | awk '/^controlpath / {print $2}')
    if [[ -n "$ctl_path" && -e "$ctl_path" ]]; then
        ssh -o ControlPath="$ctl_path" -O check "$host" 2>/dev/null && return 0
        echo "$(date '+%H:%M:%S') - removing stale control socket: $ctl_path"
        rm -f "$ctl_path"
    fi
}

refresh_ssh_auth_sock() {
    local sock
    for sock in /var/run/com.apple.launchd.*/Listeners /private/tmp/com.apple.launchd.*/Listeners; do
        if [[ -S "$sock" ]]; then
            export SSH_AUTH_SOCK="$sock"
            return 0
        fi
    done
}

# _wait_for_ssh <host>: block until an ssh connection to <host> works, checking every minute
_wait_for_ssh() {
    local host=$1 tmpprint=""
    while true; do
        refresh_ssh_auth_sock
        ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" true 2>/dev/null && break
        # Default SSH failed — check if stale ControlMaster socket is the cause
        if ssh -o ControlPath=none -o ConnectTimeout=10 -o BatchMode=yes "$host" true 2>/dev/null; then
            echo "$(date '+%H:%M:%S') - SSH via control socket failed but direct connection works, resetting control socket"
            _clear_stale_control_socket "$host"
            ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" true 2>/dev/null && break
        fi
        if [[ -z ${tmpprint} ]]; then
            echo "$(date '+%H:%M:%S') - SSH connection failed, waiting 1 minute before retry..."
            tmpprint=1
        fi
        sleep 60
    done
}

# _retry_ssh <host> <cmd...>: run an ssh/rsync command; on exit code 255 (ssh connection failed)
# wait for the connection via _wait_for_ssh and retry, so connection errors never reach the ERR trap
_retry_ssh() {
    local _host=$1 _rc
    shift
    while true; do
        "$@" && return 0 || _rc=$?
        [[ ${_rc} -eq 255 ]] || return ${_rc}
        echo "ssh connection to ${_host} failed (exit code 255), waiting for ssh" >&2
        _wait_for_ssh "${_host}" >&2
    done
}
