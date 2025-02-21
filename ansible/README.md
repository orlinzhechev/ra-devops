# Ansible Setup for ReconArt build&deploy infrastructure

This repository contains Ansible playbooks and roles used to set up and manage the ReconArt build and deploy infrastructure. The environment includes the following machine types:

- **jenkins**: The Jenkins master server where build pipelines are managed.
- **build win**: Windows build machines configured for performing builds.
- **tools win**: Windows machines that host additional tools used during the build and deployment process.
- **tools linux**: Linux machines that host additional tools for building and deploying applications.
- **artifactory**: The JFrog Artifactory server used as the artifact repository.

## Playbooks

- **build_win.yml**
  Configures Windows build machines. It performs connectivity checks using the win_ping module and applies roles for common Windows tasks, build-specific settings, and swarm configuration for Windows agents.

- **deploy_jfrog.yml**
  Deploys the JFrog Artifactory server along with its dependencies. It uses roles from the jfrog.platform collection (for nginx SSL, PostgreSQL, and Artifactory) and optionally a custom role (artifactory-conf) to override generated configurations with known-working templates.

Additional playbooks are used for configuring Jenkins, Linux tools, and Windows tools hosts.

## Variables Management

Common variables (for example, those defined in *artifactory-vars.yml* and *artifactory-secret-vars.yml*) are stored globally and loaded by the playbooks. This ensures consistency across the jfrog.platform roles and the custom roles (such as artifactory-conf) and avoids duplication of configuration data.

## Usage Examples

To run the playbook for a specific group of hosts, use commands such as:

- For Jenkins hosts:
  ```bash
  ansible-playbook -i inventory.ini deploy_jfrog.yml --limit jenkins_hosts
  ```

- For Windows build machines:
  ```bash
  ansible-playbook -i inventory.ini build_win.yml --limit build_win_hosts
  ```

- For Linux tools hosts:
  ```bash
  ansible-playbook -i inventory.ini build_win.yml --limit tools_linux_hosts
  ```

- For Windows tools hosts:
  ```bash
  ansible-playbook -i inventory.ini build_win.yml --limit tools_win_hosts
  ```

- For Artifactory:
  ```bash
  ansible-playbook -i inventory.ini deploy_jfrog.yml --limit artifactory_hosts
  ```

## Final Notes on JFrog Artifactory Installation

The deployment using the jfrog.platform collection has been challenging. The JFrog Artifactory installation includes an embedded JDK (JDK 21 for Artifactory 7.104.x and later) and manages its own configuration via system.yaml. In our setup:
- A custom role (artifactory-conf) can be used to override default configurations (such as system.yaml and nginx’s artifactory.conf) if the auto-generated configuration from the jfrog.platform roles does not work correctly.
- All configuration overrides are preserved in Git for reference.
- Always test any changes in a staging environment before deploying to production.
- This repository is provided "as is" without any warranty.

