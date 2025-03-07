# Prometheus Dynamic Service Discovery

This document describes the implementation of dynamic service discovery for Prometheus monitoring at ReconArt, which allows monitoring hosts to be added without restarting the Prometheus service.

## Overview

The monitoring system uses Prometheus file-based service discovery, which enables automatic detection of new targets by placing configuration files in designated directories. This approach eliminates the need to restart Prometheus when adding new hosts to monitor.

## Directory Structure

### On Prometheus Server

- `/etc/prometheus/prometheus.yml` - Main Prometheus configuration
- `/etc/prometheus/scrape_configs/` - Directory containing job configurations
  - `jenkins.yml` - Jenkins monitoring configuration
  - `artifactory.yml` - Artifactory monitoring configuration
  - `build_nodes.yml` - Windows build nodes configuration
  - `reconart_dev.yml` - ReconArt development environment configuration
  - `reconart_test.yml` - ReconArt test environment configuration
  - `reconart_prod.yml` - ReconArt production environment configuration
- `/etc/prometheus/file_sd/` - Directory for dynamic service discovery files
  - `build_nodes/` - Windows build machines configuration files
  - `reconart_dev/` - ReconArt development environment hosts
  - `reconart_test/` - ReconArt test environment hosts
  - `reconart_prod/` - ReconArt production environment hosts

## Configuration Files

### Job Configuration

Each job type has a configuration file in `/etc/prometheus/scrape_configs/`. Example for Windows build nodes:

```yaml
# Dynamic configuration for build nodes
scrape_configs:
  - job_name: 'build_nodes'
    file_sd_configs:
      - files:
        - '/etc/prometheus/file_sd/build_nodes/*.yml'
        refresh_interval: 5m
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
```

### Target Configuration

Each target has its own YAML file in the appropriate directory under `/etc/prometheus/file_sd/`. Example for a build node:

```yaml
- targets:
  - '10.10.102.235:9182'
  labels:
    environment: dev
    role: build
    os: windows
    hostname: VRASOF10BUILD03
```

## Adding New Hosts

### Windows Build Nodes

1. Install Windows Exporter on the host:
   ```powershell
   choco install prometheus-windows-exporter.install -y
   ```

2. Add a firewall rule to allow external connections:
   ```powershell
   New-NetFirewallRule -DisplayName "Windows Exporter" -Direction Inbound -LocalPort 9182 -Protocol TCP -Action Allow
   ```

3. Create a target file on the Prometheus server:
   ```bash
   cat > /etc/prometheus/file_sd/build_nodes/build04.yml << EOF
   - targets:
     - '10.10.102.XXX:9182'
     labels:
       environment: dev
       role: build
       os: windows
       hostname: VRASOF10BUILD04
   EOF
   
   chown prometheus:prometheus /etc/prometheus/file_sd/build_nodes/build04.yml
   ```

4. Verify the target appears in Prometheus (within 5 minutes)

### ReconArt Environment Hosts

Follow the same pattern but use the appropriate directory:

```bash
cat > /etc/prometheus/file_sd/reconart_dev/app01.yml << EOF
- targets:
  - '10.20.30.40:9100'  # Node Exporter for Linux
  labels:
    environment: dev
    role: application
    component: reconart
    hostname: app01
EOF

chown prometheus:prometheus /etc/prometheus/file_sd/reconart_dev/app01.yml
```

## Exporters Used

- **Windows Exporter** - For Windows hosts (port 9182)
- **Node Exporter** - For Linux hosts (port 9100)
- **SQL Server Exporter** - For MS SQL databases (port 9187)

## Automation with Ansible

The Ansible playbook `install_monitoring.yml` configures the Prometheus server, while the playbook `build_win.yml` can be used to install Windows Exporter on Windows hosts:

```bash
# Setup Prometheus server
ansible-playbook -i inventory.ini install_monitoring.yml

# Install Windows Exporter on build nodes
ansible-playbook -i inventory.ini build_win.yml -e "run_windows_exporter_install=true"
```

## Common PromQL Queries

- Memory usage in GB:
  ```
  (windows_cs_physical_memory_bytes - windows_os_physical_memory_free_bytes) / 1024 / 1024 / 1024
  ```

- CPU usage percentage:
  ```
  100 - (avg by (instance) (irate(windows_cpu_time_total{mode="idle"}[5m])) * 100)
  ```

- Disk space usage percentage:
  ```
  100 - ((windows_logical_disk_free_bytes / windows_logical_disk_size_bytes) * 100)
  ```

## Version Control Strategy

- Base Prometheus configuration is managed through Ansible roles
- Host-specific configuration files are stored in Git repository
- Process to add new hosts:
  1. Automated Ansible playbook adds exporter software
  2. Jenkins job creates host configuration file in Git
  3. Jenkins job copies file to Prometheus server

## Benefits of Dynamic Service Discovery

1. No need to restart Prometheus when adding new hosts
2. Better organization of configuration by environment and role
3. Easier maintenance and troubleshooting
4. Simplified automation through CI/CD pipelines
