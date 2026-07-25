set1=("greatrawr" 18900)
set2=("ferragon" 9800 3031)
for array_ref in set1[@] set2[@]; do
    current=("${!array_ref}")
    host="${current[0]}"
    ports=("${current[@]:1}")
    for port in "${ports[@]}"; do
        tmp=$(lsof -t -i :"$port" 2>/dev/null || true)
        # [[ -n $tmp ]] && kill -9 $tmp
        ssh -o ConnectTimeout=5 -o ControlPath=none -f -N -L "${port}:localhost:${port}" \
            -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
            -o ExitOnForwardFailure=yes "$host" && echo "$port succeed" || echo "Port $port tunnel failed/active"

    done
done
