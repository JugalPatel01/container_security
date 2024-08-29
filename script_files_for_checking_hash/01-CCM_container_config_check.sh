#!/bin/bash

### documentation start 
# for more checks we can refers curl --unix-socket /var/run/docker.sock http://localhost/containers/<container_id>/stats
# there are also most all the properties which are running for a speicfic container.
# for more about docker stats refers https://docs.docker.com/reference/cli/docker/container/stats/
### documentation end 

LOG_FILE="container_checks.log"

# --------------------------------Function to extract configuration value from a JSON file--------------------------------
extract_config_value() {
    local file="$1"
    local key="$2"
    jq -r "$key" "$file"
}

# --------------------------------Function to check CPU limits--------------------------------
check_cpu_limits() {

    local container_id="$1"
    local nanocpus="$2"
    local container_name="$3"
    
    local cpu_usage
    cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" "$container_id" | tail -n 1 | sed 's/%//')

    cpu_quota=$(cat /sys/fs/cgroup/system.slice/docker-$container_id.scope/cpu.max | awk '{print $1}')
    cpu_period=$(cat /sys/fs/cgroup/system.slice/docker-$container_id.scope/cpu.max | awk '{print $2}')

    # here check for the cpu usage is meaning less because we are giving a cpushare, cpuperiod and cpuquota
    # we can find cpushare by 
        # cpu share = (container cpu% / total cpu%) * 1024  (because bydefault value of the cpu share of docker is 1024)
    # for checking cpu quota and cpu period
        # to find the cgroup of the container use below command : 
            # sudo systemctl status docker-<container_id>.scope
        # in that cgroup find the set properties for that container by below command : 
            # systemctl show docker-<container_id>.scope -p CPUQuota -p CPUShares -p CPUAccounting

    if [ "$cpu_quota" = "max" ] || [ "$cpu_period" = "max" ]; then
        # cpu_limit=$(echo "scale=2; (( $(cat /proc/cpuinfo | grep processor | wc -l) * 100 ) / 2 )" | bc)
        cpu_limit=$(echo "scale=2; (( $(cat /proc/cpuinfo | grep processor | wc -l) * 100 ) / 2 + 1)" | bc)
        # echo "----------------------------------------------------------------" >> "$LOG_FILE"
        # echo "No CPU limit set for container $container_name ($container_id)" >> $LOG_FILE
        # echo "" >> $LOG_FILE
    else
        # cpu_limit=$(echo "scale=2; ($cpu_quota / $cpu_period * 100)" | bc)
        cpu_limit=$(echo "scale=2; ($cpu_quota / $cpu_period * 100 + 1)" | bc)
        # echo $cpu_limit, $cpu_quota, $cpu_period
    fi

    if [ "$(echo "$cpu_usage > $cpu_limit" | bc)" -eq 1 ]; then
        echo "----------------------------------------------------------------" >> "$LOG_FILE"
        echo "Changes detected on $(date)" >> "$LOG_FILE"
        echo "CPU limit exceeded for container $container_name ($container_id): expected $cpu_limit%, actual $cpu_usage%" >> $LOG_FILE
        echo "" >> $LOG_FILE

        echo "CPU limit exceeded($cpu_usage) for contianer $container_name : $container_id"
                    echo "Options:"
                    echo "1. Remove $container_name container from network"
                    echo "2. Stop $container_name container immediately"
                    echo "3. Keep running $container_name container and inform other containers"
                    echo "choose an option : "
                    read choosed_option < /dev/tty
                    # echo $?
                    # echo "choosed option is : $choosed_option"
                    case $choosed_option in
                        1)
                            echo "option 1 choosed : disconnect container $container_id from network"
                            docker network disconnect default "$container_id"
                            ;;
                        2)
                            echo "option 2 choosed : stopping container"
                            docker stop "$container_id"
                            ;;
                        3)
                            echo "option 3 choosed : all container informed to tighten security."
                            docker exec -it "$container_id" /bin/sh -c "echo 'Security alert: "$container_name" using more cpu($cpu_usage) then given'"
                            ;;
                        *)
                            echo "Invalid option. Skipping."
                            ;;
                    esac
    # else
        # echo "$container_name :: $container_id"
        # echo "cpu usage is : $kernel_value"
    fi
}

# --------------------------------Function to check memory limits--------------------------------
check_memory_limits() {
    local container_id="$1"
    local memory_set_limit_from_json="$2"
    local container_name="$3"
    local memory_usage
    local memory_max=$(cat /sys/fs/cgroup/system.slice/docker-$container_id.scope/memory.max | awk '{print $1}')
    # local memory_usage=$(docker stats --no-stream --format "{{.MemUsage}}" "$container_id" | awk '{print $1}')
    local memory_usage=$(cat /sys/fs/cgroup/system.slice/docker-$container_id.scope/memory.current | awk '{print $1}')

     if [ "$memory_max" != "max" ]; then
        # echo "----------------------------------------------------------------" >> "$LOG_FILE"
            # echo "No CPU limit set for container $container_name ($container_id)" >> $LOG_FILE
        # echo "" >> $LOG_FILE
        # memory_usage_percentage=$((memory_usage * 100 / memory_max))


        if [ "$(echo "$memory_usage > $memory_max" | bc)" -eq 1 ]; then
            echo "----------------------------------------------------------------" >> "$LOG_FILE"
            echo "Changes detected on $(date)" >> "$LOG_FILE"
            echo "Memory limit exceeded for container $container_name ($container_id): expected $memory_max%, actual $memory_usage%" >> $LOG_FILE
            echo "" >> $LOG_FILE

            echo "Memory limit exceeded for contianer $container_name : $container_id"
                        echo "Options:"
                        echo "1. Remove $container_name container from network"
                        echo "2. Stop $container_name container immediately"
                        echo "3. Keep running $container_name container and inform other containers"
                        echo "choose an option : "
                        read choosed_option < /dev/tty
                        # echo $?
                        # echo "choosed option is : $choosed_option"
                        case $choosed_option in
                            1)
                                echo "option 1 choosed : disconnect container $container_id from network"
                                docker network disconnect default "$container_id"
                                ;;
                            2)
                                echo "option 2 choosed : stopping container"
                                docker stop "$container_id"
                                ;;
                            3)
                                echo "option 3 choosed : all container informed to tighten security."
                                docker exec -it "$container_id" /bin/sh -c "echo 'Security alert: "$container_name" uses more memory then allocated.'"
                                ;;
                            *)
                                echo "Invalid option. Skipping."
                                ;;
                        esac
        
        fi
    fi
}

# --------------------------------Main function to check container configurations--------------------------------
check_container_configs() {
    local container_id="$1"
    local config_v2_file="/var/lib/docker/containers/$container_id/config.v2.json"
    local hostconfig_file="/var/lib/docker/containers/$container_id/hostconfig.json"
    local container_name=$(extract_config_value "$config_v2_file" '.Name')
    local container_small_id=$(extract_config_value "$config_v2_file" '.Config.Hostname')
    local check_running_status=$(extract_config_value "$config_v2_file" '.State.Running')


    ## Check if configuration files exist
    if [ ! -f "$config_v2_file" ]; then
        echo "Error: config.v2.json not found for container $container_id"
        return 1
    fi

    if [ ! -f "$hostconfig_file" ]; then
        echo "Error: hostconfig.json not found for container $container_id"
        return 1
    fi

    ## Extract relevant configurations from config.v2.json
    
    cpu_limit=$(extract_config_value "$hostconfig_file" '.NanoCpus')
    memory_limit=$(extract_config_value "$hostconfig_file" '.Memory')

    ## Check the extracted configurations against the Docker settings
    if [ "$check_running_status" = "true" ]; then
        check_cpu_limits "$container_id" "$cpu_limit" "$container_name"
        check_memory_limits "$container_id" "$memory_limit" "$container_name"
    fi

    # echo "Configuration checks completed for container $container_name : $container_small_id."
}

# --------------------------------Get list of all container IDs--------------------------------
container_ids=$(docker ps -a --no-trunc -q)


while true; do
    for container_id in $container_ids; do
        check_container_configs "$container_id"
    done
    # echo "iteration over."
    sleep 50
done

