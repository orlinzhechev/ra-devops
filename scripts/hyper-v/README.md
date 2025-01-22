# Hyper-V scripts

## To fetch a configuration 
```
.\Fetch-VM-Config.ps1 localhost win11
```

## To Generate a Template Config Based on real VM
```
.\fetch-vm-config.ps1 localhost win11 -GenerateTemplate
```

## To Create a VM based on the template-config.json
```
.\Create-VM.ps1 -VMName "new-template" -HyperVServer "localhost" -TargetDisk "C:\Hyper-V"
```

(to be continued...)
