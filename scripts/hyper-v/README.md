# Hyper-V scripts

## To fetch a configuration 
- Local Hyper-V server
```
.\Fetch-VM-Config.ps1 win11 localhost 
```

- Remote Hyper-V server that is connected to the local Hyper-V client
```
.\Fetch-VM-Config.ps1 win11 prasof10
```

## Example How To Generate a Template Config Based on real VM
- Local Hyper-V server
```
.\Fetch-VM-Config.ps1 localhost win11 -GenerateTemplate
```

- Remote Hyper-V server that is connected to the local Hyper-V client
```
.\Fetch-VM-Config.ps1 win11 prasof10 -GenerateTemplate
```

## To Create a VM based on the config-template.json
```
.\Create-VM.ps1 -VMName "win11" -HyperVServer "localhost" -TargetDisk "C:\Hyper-V"
```
.\Create-VM.ps1 -VMName "win11" -HyperVServer "PRASOF10" -TargetDisk "E:\Hyper-V" -ConfigFile ".\config-template.json.prasof10"


## Steps to Create a VM based on the Structure of an existing one
That approach allows to create a template from an existing machine and use it to create one or more machines based on that

1. First create the template based on an existing machine. No need to stop the VM to fetch the configuration
```
.\Fetch-VM-Config.ps1 VRASOF10DB1 prasof10 -GenerateTemplate -OutputFile config-template.json
```

2. Check the generated template
```
cat .\output\config-template.json
```

3. Execute the script in Dry Run mode to check if everything will be created as expected

```
.\Create-VM.ps1 -VMName "win-testdb" -HyperVServer "prasof10" -TargetDisk "E:\Hyper-V" -ConfigFile .\output\config-template.json -DryRun
```

4. Final execution
```
.\Create-VM.ps1 -VMName "win-testdb" -HyperVServer "prasof10" -TargetDisk "E:\Hyper-V" -ConfigFile .\output\config-template.json 
```

## Configuration Examples
There are couple of configuration examples in subdirectory `config-examples`
