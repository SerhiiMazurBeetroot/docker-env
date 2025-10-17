# nghost (Nginx + Hosts)

nghost is a lightweight tool for injecting entries into the `HOSTS_FILE` file, enabling local name resolution for Docker containers.

It listens for Docker events via the mounted docker.sock, automatically detecting running containers and mapping their IP addresses to hostnames.

Entries are added to the host's `HOSTS_FILE` file within the `dockerwp` network, ensuring seamless connectivity. The tool continuously updates the file, keeping track of newly started or stopped containers.
