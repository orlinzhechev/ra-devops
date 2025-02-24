# I. Preparation

## 1. Creating a Template from an Existing Machine

```sh
cd scripts/hyper-v
.\Fetch-VM-Config.ps1 -VMName VRASOF10BUILD01 -HyperVServer prasof10 -GenerateTemplate -OutputFile template-config-build.json
```

The output will be stored in the `output` directory.

This script extracts the configuration of an existing machine and saves it as a template, which can later be used to create a new machine with another script.

## 2. Creating a Machine from a Template

```sh
.\Create-VM.ps1 -VMName "VRASOF10BUILD03" -TargetPath "E:\Hyper-V" -ConfigFile .\output\template-config-build.json -HyperVServer prasof10 -DryRun
```

Remove `-DryRun` to actually create the VM.

## 3. Installing the Operating System

Start the machine and follow the installation steps.

## 4. Initial Setup

- Open the `win_initial_setup.ps1` script:
  ```sh
  cat win_initial_setup.ps1
  ```
- Copy the content.
- Create a file on the desktop named `win_initial_setup.ps1` and paste the content.
- Run the script by right-clicking it and selecting `Run with PowerShell`.

## 5. Checking the IP Address

Run the following command:

```sh
ipconfig
```

## 6. Testing SSH Access

```sh
ssh administrator@IP_ADDRESS
```

# II. Ansible Setup

## 1. Access Jenkins

Go to [Jenkins](https://jenkins.reconart.net).

## 2. Adding the Machine for Access

Use the Jenkins job [setup-add-ssh-host](https://jenkins.reconart.net/view/Setup%20Jobs/job/setup-add-ssh-host/).

- Execute **Build with Parameters** and set the IP and the user (`administrator` for Windows OS and `bootstrap` for Linux).
- This allows access to the machine from the Linux **Tools** machine.

## 3. Setting Up the Machine as a Build Machine

Use the Jenkins job [setup-base-pipeline](https://jenkins.reconart.net/view/Setup%20Jobs/job/setup-base-pipeline/).

- **HOST\_IP** - the IP of the new machine
- **ANSIBLE\_ROLE**: `build_win_hosts`
- **MACHINE\_NAME**: `VRASOFBUILDxx`
- **GIT\_USER**: (user to access the repo at GitHub)
- **GIT\_BRANCH**: Git branch to use

`GIT_USER` and `GIT_BRANCH` should be changed only when working on the `ra-devops` repo.

Hit **Build**! The process takes approximately 30 minutes.

## 4. Verifying the Machine in Jenkins

If everything is set up correctly, the machine should appear in the Jenkins agent list: [Jenkins Agents](https://jenkins.reconart.net/computer/).

A suffix will be added to the name automatically when the Swarm agent connects (dynamic agent connection in Jenkins) to avoid potential duplicate name issues.

You can check the machine's labels by clicking on the new machine and reviewing **Labels**. The label `build_ra` should be present, indicating that the machine is available as a build machine for the ReconArt product.

## 5. Trusting bitbucket.reconart.net:7999

1. Open an SSH session to the build machine:
   ```sh
   ssh administrator@<new_machine_ip>
   ```

2. Attempt an SSH connection manually to trigger the trust prompt:
   ```sh
   ssh -p 7999 git@bitbucket.reconart.net
   ```
   If prompted, confirm adding the host to `known_hosts`.

3. Alternatively, use Git to fetch a repository, which will also prompt for trust:
   ```sh
   mkdir temp
   cd temp
   git init
   git fetch --no-tags --force --progress --depth=1 -- ssh://git@bitbucket.reconart.net:7999/~orlin.zhechev/reconart.git +refs/heads/*:refs/remotes/origin/*
   ```
   This will prompt to add the host to `known_hosts`.

After this step, the build process should be able to start without SSH-related trust issues.


