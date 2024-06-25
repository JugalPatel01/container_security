#!/bin/bash

# Function to collect CPU and memory usage
collect_metrics() {
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    echo "$cpu_usage,$mem_usage"
}

# Function to collect running processes
collect_processes() {
    ps -eo comm --no-headers | grep -v -E "^(kworker|tracker-extract)" | sort | uniq > "$1"
}

# Function to compare running processes
compare_processes() {
    diff -u "$1" "$2" | grep -E "^\+" | cut -c 2-
}

# Duration and interval for monitoring (in seconds)
duration=300
interval=1

# Run monitoring without the security script
echo "Running monitoring without the security script..."
start_time=$(date +%s)
while [ $(($(date +%s) - start_time)) -lt $duration ]; do
    collect_metrics >> metrics_without_script.csv
    sleep $interval
done

# Collect running processes without the security script
collect_processes "processes_without_script.txt"

# Run monitoring with the security script
echo "Running monitoring with the security script..."
start_time=$(date +%s)
./config_check.sh &
./hash_cmp.sh &


while [ $(($(date +%s) - start_time)) -lt $duration ]; do
    collect_metrics >> metrics_with_script.csv
    sleep $interval
done

# Collect running processes with the security script
collect_processes "processes_with_script.txt"

# Stop the security script
pkill -f config_check.sh
pkill -f hash_cmp.sh

echo "Benchmarking completed."

# Compare running processes
echo "Comparing running processes..."
additional_processes=$(compare_processes "processes_without_script.txt" "processes_with_script.txt")

if [ -z "$additional_processes" ]; then
    echo "No additional relevant processes found."
else
    echo "Additional relevant processes found:"
    echo "$additional_processes"
    echo "Please review the additional processes to ensure they are expected."
fi

rm ./processes_with_script.txt ./processes_without_script.txt