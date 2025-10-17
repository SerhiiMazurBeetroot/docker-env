#!/usr/bin/python3
import docker
import argparse
import shutil
import signal
import time
import sys
import os

label_name = "docker.env.domains"
enclosing_pattern = "#-----------docker-env-domains----------\n"
hosts_path = "/tmp/hosts"
hosts = {}


def signal_handler(signal, frame):
    global hosts
    hosts = {}
    update_hosts_file()
    sys.exit(0)


def main():
    # register the exit signals
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    args = parse_args()
    global hosts_path
    hosts_path = args.file

    dockerClient = docker.APIClient(base_url="unix://%s" % args.socket)
    events = dockerClient.events(decode=True)
    # get running containers
    for c in dockerClient.containers(quiet=True, all=False):
        container_id = c["Id"]
        container = get_container_data(dockerClient, container_id)
        hosts[container_id] = container

    update_hosts_file()

    # listen for events to keep the hosts file updated
    for e in events:
        if e["Type"] != "container":
            continue

        status = e["status"]
        if status == "start":
            container_id = e["id"]
            container = get_container_data(dockerClient, container_id)
            hosts[container_id] = container
            update_hosts_file()

        if status == "stop" or status == "die" or status == "destroy":
            container_id = e["id"]
            if container_id in hosts:
                hosts.pop(container_id)
                update_hosts_file()

        if status == "rename":
            container_id = e["id"]
            if container_id in hosts:
                container = get_container_data(dockerClient, container_id)
                hosts[container_id] = container
                update_hosts_file()


def get_container_data(dockerClient, container_id):
    # Extract all the info with the Docker API
    info = dockerClient.inspect_container(container_id)
    container_hostname = info["Config"]["Hostname"]

    # Extract VIRTUAL_HOST from environment variables
    env_vars = info["Config"].get("Env", [])
    virtual_host = None
    for env in env_vars:
        if env.startswith("VIRTUAL_HOST="):
            virtual_host = env.split("=", 1)[1].strip()  # Extract value and trim spaces
            break  # Stop after finding the first match

    # Ensure VIRTUAL_HOST is a list and remove empty entries
    domains = (
        [host.strip() for host in virtual_host.split(",") if host.strip()]
        if virtual_host
        else []
    )

    # Skip empty results
    if not domains:
        return []

    result = []

    # Ensure the container is in the 'dockerwp' network
    if "dockerwp" in info["NetworkSettings"]["Networks"]:
        network_data = info["NetworkSettings"]["Networks"]["dockerwp"]

        # Handle possible None value for Aliases
        aliases = network_data.get("Aliases", []) or []
        aliases.append(container_hostname)

        # Convert aliases to lowercase for case-insensitive matching
        aliases_lower = [alias.lower() for alias in aliases]

        # Exclude containers that have "nginx" in their name or aliases
        if any("nginx" in alias for alias in aliases_lower):
            return []

        result.append(
            {
                "ip": "127.0.0.1",
                "domains": domains,
            }
        )

    return result


def update_hosts_file():
    if len(hosts) == 0:
        print("Removing all hosts before exit...")
    else:
        print("Updating hosts file with:")

    for id, addresses in hosts.items():
        for addr in addresses:
            print("ip: %s domains: %s" % (addr["ip"], addr["domains"]))

    # read all the lines of thge original file
    lines = []
    with open(hosts_path, "r+") as hosts_file:
        lines = hosts_file.readlines()

    # remove all the lines after the known pattern
    for i, line in enumerate(lines):
        if line == enclosing_pattern:
            lines = lines[:i]
            break

    # remove all the trailing newlines on the line list
    if lines:
        while lines[-1].strip() == "":
            lines.pop()

    # append all the domain lines
    if len(hosts) > 0:
        lines.append("\n\n" + enclosing_pattern)

        for id, addresses in hosts.items():
            for addr in addresses:
                lines.append("%s  %s\n" % (addr["ip"], "   ".join(addr["domains"])))

        lines.append("#-----Do-not-add-hosts-after-this-line-----\n\n")

    # write it on the auxiliar file
    aux_file_path = hosts_path + ".aux"
    with open(aux_file_path, "w") as aux_hosts:
        aux_hosts.writelines(lines)

    # replace etc/hosts with aux file, making it atomic
    shutil.move(aux_file_path, hosts_path)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Synchronize running docker container IPs with host /etc/hosts file."
    )
    parser.add_argument(
        "socket",
        type=str,
        nargs="?",
        default="tmp/docker.sock",
        help="The docker socket to listen for docker events.",
    )
    parser.add_argument(
        "file",
        type=str,
        nargs="?",
        default="/tmp/hosts",
        help="The /etc/hosts file to sync the containers with.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    main()
