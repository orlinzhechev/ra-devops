# ra-devops
ReconArt DevOps repository

This is an initial commit, tested once on a Windows machine but requires retesting.
The testing environment is set up on Orlin's laptop:
- **tools**: Ubuntu machine used to orchestrate the environment, running on VBox.
- **win11**: Windows 11 Pro machine used to test the Ansible setup, running on Hyper-V.

### Known Issues on Windows
For Windows, SSH access needs to be configured using OpenSSH keys (password-based authentication is not supported). 

There is an ongoing debate regarding the preferred access method for Ansible: SSH or WinRM. Historically, WinRM was the default method, but current documentation suggests that SSH is also a valid option. We will determine the better option during testing.

## Usage
1. Install a new Windows machine.
2. Create a user **bootstrap** (pass t-r).
3. Run the following PowerShell script as administrator:  
   `scripts\win_initial_setup.ps1`
4. Ensure you have the `~/.ssh/bootstrap_rsa` private key available.
5. Test SSH access to the machine:  
   `ssh -i ~/.ssh/bootstrap_rsa bootstrap@192.168.57.11 'echo "Connection successful"'`  
   You should receive the following:  
   `Connection successful`
6. Test Ansible access:  
   `cd ansible`  
   `ansible-playbook -i inventory.ini ping.yml`  
   Expected output:  

    ```
    PLAY [Test connections to windows hosts] **********************************************************************

    TASK [Gathering Facts] ****************************************************************************************
    ok: [windows]

    TASK [Check access] *******************************************************************************************
    ok: [windows]

    PLAY RECAP ****************************************************************************************************
    windows                    : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

    ```

7. Run the `build_win.yml` playbook. It installs all needed software to build ReconArt.sln
   `cd ansible`
   `ansible-playbook -i inventory.ini build_win.yml'

# TODO
1. Still working on ReconArt After Commit. It uses 2022. It builds another solution. We still have probelm with WiX setup

2. Production build uses VS 2017 (v15). So need to add installation steps for vs2015 as well
