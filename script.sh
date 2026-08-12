#!/bin/bash

parse_function() {
    line=$1
    port=0
    r_ip=0
    l_ip=0
    if [[ ! $line =~ [0-9] ]]; then
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

ports=()
processes=()
pids=()
protocols=()
r_ips=()
l_ips=()
states=()

for i in {0..65535}; do
    ports[i]=0;
    processes[i]=0;
    pids[i]=0;
    protocols[i]=0;
    r_ips[i]=0;
    l_ips[i]=0;
    states[i]=0;
done


while read -r line; do
    read -r port l_ip r_ip < <(parse_function "$(echo "$line" | awk '{print $9}')")
    if [[ $port -ne -1 ]]; then
        ports[port]=$port
        l_ips[port]=$l_ip
        r_ips[port]=$r_ip
        processes[port]=$(echo "$line" | awk '{print $1}')
        pids[port]=$(echo "$line" | awk '{print $2}')
        protocols[port]=$(echo "$line" | awk '{print $8}')
        states[port]=$(echo "$line" | awk '{print ($10 ? $10 : "(LISTEN)")}')
    fi
done < <(lsof -i4 -P -n | tail -n +2)

printf "%-5s | %-5s | %-10s | %-10s | %-20s | %-20s | %-20s\n" "PORT" "PID" "PROCESS" "PROTOCOL" "LOCAL IP" "REMOTE IP:PORT" "STATE"

for i in {0..65535}; do
    if [[ ${ports[i]} -ne 0 ]]; then
        printf "%-5s | %-5s | %-10s | %-10s | %-20s | %-20s | %-20s\n" "${ports[i]}" "${pids[i]}" "${processes[i]}" "${protocols[i]}" "${l_ips[i]}" "${r_ips[i]}" "${states[i]}"
    fi
done
