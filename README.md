# Container Security


**Objective:** By utilizing extra system resources, we can further secure our containers from attacks that target the integrity and availability of containers in a containerized environment.

**About repository:** This repository contains two scripts, CHM (Continuous Hash Monitoring) and CCM (Continuous Configuration Monitoring), along with related documents and required assets that are useful for protecting the availability and integrity of containerized environments.

## Environment Requirements

To run the scripts, ensure that your environment meets the following requirements:

1. OS: Ubuntu Jammy 22.04 LTS
2. Docker should be installed
   - Refer to the [Docker installation guide for Ubuntu](https://docs.docker.com/engine/install/ubuntu/) for installation instructions
   - The container engine should be Docker Engine 27.0
   - Install all the dependencies according to the Docker version

## Steps to Run the Project

1. Read about Docker and dockerd runtime from the [`docker_dockerd_tricks`](./docker_dockerd_tricks/) folder.
2. Build vulnerable Docker images present in the [`docker_image_vul_test`](./docker_image_vul_test/) folder.
3. Start containers according to your needs, such as with restricted CPU usage or restricted memory usage, etc.
4. Check your running containers' overview using the script mentioned in the [`docker_inspect_config_file_template`](./docker_inspect-config_file_template/).
5. Before starting the CHM script, run the [`02a-hash_init.sh`](./script_files_for_checking_hash/02a-hash_init.sh) script, which generates hashes of your current container states. Then start the [`02b-CHM_container_hash_monitoring.sh`](./script_files_for_checking_hash/02b-CHM_container_hash_monitering.sh) script to enable the CHM functionality.
6. Start the [`01-CCM_container_config_check.sh`](./script_files_for_checking_hash/02b-CHM_container_hash_monitering.sh) script to check whether any adversary has modified your container's configurations.
7. You can do benchmarking using script [`03-benchmarking_script.sh`](./script_files_for_checking_hash/03-benchmarking_script.sh) and after that you can generate graph from that benchmarks using [`04-make_graph.py`](./script_files_for_checking_hash/04-make_graph.py)

## Container Security Basics and Documentation for CHM & CCM

For detailed information about container security basics and documentation for CHM and CCM, please refer to the [container_security.pdf](./container_security.pdf) file.