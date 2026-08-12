#!/bin/bash

parse_function() {
    line=$1
    port=0
    ip=0
    if [[ ! $line =~ [0-9] ]]; then
        echo "-1 0"
        return
    fi
    if [[ $line =~ \[.*\] ]]; then
        echo "${line##*:} -"
    fi  
    if [[ $line =~ \* ]]; then
        port="${line#*:}"
    else
        port="${line#*:}"
        port="${port%%-*}"
        ip="${line%:*}"
        ip="${ip##*>}"
    fi
    echo "$port $ip"
}       

ports=()
pids=()
processes=()
ips=()
states=()

for i in {0..65535}; do
    ports[i]=0;
    pids[i]=0;
    processes[i]=0;
    ips[i]=0;
    states[i]=0;
done


while read -r line; do
    read -r port ip < <(parse_function "$(echo "$line" | awk '{print $9}')")
    if [[ $port -ne -1 ]]; then
        ports[port]=$port
        ips[port]=$ip
        pids[port]=$(echo "$line" | awk '{print $2}')
        processes[port]=$(echo "$line" | awk '{print $1}')
        states[port]=$(echo "$line" | awk '{print ($10 ? $10 : "(LISTEN)")}')
    fi
done < <(lsof -i -P -n | tail -n +2)

printf "%-5s | %-5s | %-10s | %-15s | %-20s\n" "ПОРТ" "PID" "ПРОЦЕСС" "УДАЛЕННЫЙ АДРЕС" "СОСТОЯНИЕ"

for i in {0..65535}; do
    if [[ ${ports[i]} -ne 0 ]]; then
        printf "%-5s | %-5s | %-10s | %-15s | %-20s\n" "${ports[i]}" "${pids[i]}" "${processes[i]}" "${ips[i]}" "${states[i]}"
    fi
done
