# Ansible Role: artifactory

This role was originally developed to install and configure JFrog Artifactory on Ubuntu using the native apt package (as provided by the distribution) rather than downloading a tar.gz from JFrog's website. Note that this role is still under development and is not fully complete. In its current state, it covers the following:

- **Pre-check tasks**  
  Ensuring that `/mnt/artifacts` exists, is a valid mount point, and meets capacity requirements.
- **Installation tasks for Artifactory OSS via apt**  
  - Adding the JFrog GPG key and repository.
- **Tasks to set up the master key**  
  - With options to force key regeneration.
- **A block to disable clustering**  
  - Editing the `artifactory.system.properties` file.
- **Configuration tasks for managing data directories**  
  - Data migration via symlink creation.
- **Nginx configuration tasks for Artifactory**  
  - Including SSL setup using default certificate paths and upstream definitions.

## Important Notes

- The role uses Ubuntu’s apt package for Artifactory, which may differ from the tar.gz approach used elsewhere.
- Postgres integration is not fully completed in this role.
- The configuration files (such as `system.yaml` and the nginx configuration file) were extracted from a working production system and are preserved here for future use.
- This role is kept for historical reference or if you need to complete its functionality one day; the current production deployments are now using the `jfrog.platform` collection.
- Use this role at your own risk and test thoroughly in a staging environment before deploying to production.

If further adjustments are needed, or if you plan to extend the functionality (for example, to add complete Postgres configuration or refine the Artifactory configuration), you can build on this role as a starting point.

