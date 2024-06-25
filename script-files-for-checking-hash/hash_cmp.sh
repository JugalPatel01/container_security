#!/bin/bash

# --------------------------------File where initial hashes are stored--------------------------------
HASH_FILE="container_hashes.txt"
CURRENT_HASH_FILE="current_container_hashes.txt"
LOG_FILE="container_hash_comparision.log"
COMPROMISED_CONTAINERS_LOG="compromised_containers.log"


# --------------------------------Function to extract configuration value from a JSON file--------------------------------
extract_config_value() {
    local file="$1"
    local key="$2"
    jq -r "$key" "$file"
}

# --------------------------------Function to compare hashes--------------------------------
check_hashes() {
    processed_containers=()
   
    find /var/lib/docker/containers -type f ! -name '*.log' -exec sha256sum {} \; > "$CURRENT_HASH_FILE"

    
    if ! cmp -s "$HASH_FILE" "$CURRENT_HASH_FILE"; then

        diff "$HASH_FILE" "$CURRENT_HASH_FILE" | grep -E "^(<|>)" | while read -r line; do
            
            file_path=$(echo "$line" | awk '{print $3}')
            # echo "$line"

            if [ -f "$file_path" ]; then
            
                # Extract the container ID from the file path
                container_id=$(echo "$file_path" | cut -d'/' -f6)
                # echo $container_id

                local config_v2_file="/var/lib/docker/containers/$container_id/config.v2.json"
                local container_name=$(extract_config_value "$config_v2_file" '.Name')
                local last_modified_user=$(stat -c '%U' "$file_path")


                if [[ " ${processed_containers[@]} " =~ " ${container_id} " ]]; then
                    echo "$last_modified_user changed $file_path on $(date) !!!!    " >> "$LOG_FILE"

                    continue
                fi
                processed_containers+=("$container_id")
                

                echo "----------------------------------------------------------------" >> "$LOG_FILE"
                echo "Change in container : $container_name($container_id)" >>"$LOG_FILE"
                echo "$last_modified_user changed $file_path on $(date) !!!!    " >> "$LOG_FILE"
                # echo "File: $file_path was modified by user: $last_modified_user"
                
                # Check for hash mismatches and handle them
                    echo "Hash mismatch for container $container_name ($container_id)"
                    echo "Options:"
                    echo "1. Remove from network"
                    echo "2. Stop immediately"
                    echo "3. Keep running, inform other containers"
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
                            docker exec -it "$container_id" /bin/sh -c "echo 'Security alert: Hash mismatch detected. Tighten security.'"
                            ;;
                        *)
                            echo "Invalid option. Skipping."
                            ;;
                    esac

                    # Log compromised container
                    echo "Compromised container: $container_name ($container_id)" >> "$COMPROMISED_CONTAINERS_LOG"
                    echo "User: $(docker inspect -f '{{.Config.User}}' "$container_id")" >> "$COMPROMISED_CONTAINERS_LOG"
                    echo "----------------------------------------------------------------" >> "$COMPROMISED_CONTAINERS_LOG"
            else
                echo "File: $file_path was deleted" >> "$LOG_FILE"
            fi
        done
    else
        echo "----------------------------------------------------------------" >> "$LOG_FILE"
        echo "Date : $(date)" >> "$LOG_FILE"
        echo "No changes detected in container file hashes." >> "$LOG_FILE"
    fi
}

# Main loop
while true; do
    check_hashes
    # echo "iteration complemented"
    rm $CURRENT_HASH_FILE
    sleep 50
done
