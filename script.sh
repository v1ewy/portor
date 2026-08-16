#!/bin/bash

parse_function() {
    line=$1
    port=0
    r_ip=0
    l_ip=0
    if [[ ! $line =~ [0-9] || $line == "*->"* ]]; then
        echo "-1 0 0"
        return
    fi
    if [[ $line =~ \[.*\] ]]; then
        echo "-1 0 0"
        return
    fi  
    if [[ $line =~ \* ]]; then
        port="${line#*:}"
        l_ip="0.0.0.0"
        r_ip="-"
    elif [[ $line == *"->"* ]]; then
        port="${line#*:}"
        port="${port%%-*}"
        l_ip="${line%%:*}"
        r_ip="${line##*>}"
    else 
        port="${line#*:}"
        l_ip="${line%%:*}"
        r_ip="-"
    fi
    echo "$port $l_ip $r_ip"
}       

INTERVAL=3

trap "echo -e '\nExiting...'; exit 0" INT

tput smcup
tput civis

while true; do
    active_ports=""

    while read -r line; do
        read -r port l_ip r_ip < <(parse_function "$(echo "$line" | awk '{print $9}')")
        if [[ $port -ne -1 ]]; then
            eval "tmp_ports_$port=\"$port\""
            eval "tmp_l_ips_$port=\"$l_ip\""
            eval "tmp_r_ips_$port=\"$r_ip\""
            eval "tmp_processes_$port=\"$(echo "$line" | awk '{print $1}')\""
            eval "tmp_pids_$port=\"$(echo "$line" | awk '{print $2}')\""
            eval "tmp_protocols_$port=\"$(echo "$line" | awk '{print $8}')\""
            eval "tmp_states_$port=\"$(echo "$line" | awk '{print ($10 ? $10 : "(LISTEN)")}')\""

            active_ports="$active_ports $port"
        fi
    done < <(lsof -i4 -P -n | tail -n +2)

    printf "\033[H\033[2J\033[3J"
    printf "Updating every %s sec. To exit, press Ctrl+C\n" "$INTERVAL"
    printf "%-5s | %-5s | %-10s | %-10s | %-20s | %-20s | %-20s\n" "PORT" "PID" "PROCESS" "PROTOCOL" "LOCAL IP" "REMOTE IP:PORT" "STATE"

    sorted_ports=$(echo "$active_ports" | tr ' ' '\n' | sort -n | uniq)

    for i in $sorted_ports; do
        eval "p_port=\$tmp_ports_$i"
        eval "p_pid=\$tmp_pids_$i"
        eval "p_proc=\$tmp_processes_$i"
        eval "p_proto=\$tmp_protocols_$i"
        eval "p_local=\$tmp_l_ips_$i"
        eval "p_remote=\$tmp_r_ips_$i"
        eval "p_state=\$tmp_states_$i"

        printf "%-5s | %-5s | %-10s | %-10s | %-20s | %-20s | %-20s\n" "$p_port" "$p_pid" "$p_proc" "$p_proto" "$p_local" "$p_remote" "$p_state"
        unset "tmp_ports_$i" "tmp_pids_$i" "tmp_processes_$i" "tmp_protocols_$i" "tmp_l_ips_$i" "tmp_r_ips_$i" "tmp_states_$i"
    done

    sleep "$INTERVAL"
done