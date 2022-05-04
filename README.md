# application-digitalocean-chaosmonkey
[![Module version badge](https://img.shields.io/badge/Module-v1.0.0-green)](https://shields.io/)

![ChaosMonkey from Netflix](https://netflix.github.io/chaosmonkey/logo.png)

## How to use the ChaosMonkey

### Deploy the ChaosMonkey
To deploy the chaosmonkey, please use the followinf terraform module. [terraform-digitalocean-chaosmonkey](https://github.com/buehlmannpa/terraform-digitalocean-chaosmonkey)

### Config options
Examples are displayed under the following list in the *config example*
| Name | Description |
|------|------|
|`"excluded-weekdays"`| A list of weekdays (short) without **any** spaces |
|`"excluded-namespaces"` | A list of kubernetes namespaces without **any** spaces |
|`"exclude-new-pods"`| *Yes* will not delete pods until they are older then 1 hour. *No* will kill any pod at any time |
|`"delete-period"`| A time period with a number and a unit. **m**<60; **h**<24;**d**<32  |
|`"backup-time"`| A fixed time at which the backup should be performed (00:00) |

### Config example
```bash
excluded-weekdays=SA,SO
excluded-namespaces=default,kube-node-lease,kube-public
exclude-new-pods=yes
delete-period=5m
backup-time=23:23
```

## Script documentation

### chaosmonkey.sh
This script is the main component of the whole project. All the logic to eliminate pods and check the configuration parameters from above is located here.

The Chaos Monkey app is automatically started with a cronjob (check with **crontab -l**). Each time the app runs, it selects a random namespace and pod to eliminate.

The following logfiles are used for the chaosmonkey:
| File | Description | Backup |
|------|------|------|
|`"/data/chaos-monkey/chaosmonkey.log"` | This is the current log file used for 24 hours until the backup job creates a backup and cleans the file. Every activity of the chaos monkey is logged in this file | yes |
|`"/data/chaos-monkey/chaosmonkey-color.log"` | As above, but with the difference that this file retains the colored output and will not be backuped | no |

The code is structured with the following keywords in the comments
- DECLARATION: Declaration of the variables of the whole script
- FUNCTION: Definition of a function like *return info message*
- PART: Executable steps like *eliminate a pod*

#### Multiple clusters

The Chaos Monkey can manage one or more DigitalOcean kubernetes clusters simultaneously. For this purpose, a loop has been defined in PART *Eliminate Pods* that iterates through the list of all kubectl contexts. These are provided by the *get_kubeconfig.sh* script.

To add or remove Kubernetes clusters, please follow the instructions in the description of the *get_kubeconfig.sh* script.

#### HINT FOR THE WEBPAGE

A symbolic link is created in the PART *Eliminate Pods* that the webpage could display the current logs of this file withing the apache root folder.

### get_kubeconfig.sh
This script, as the name implies, gets the current kubeconfig (one or more) of the defined kubernetes clusters and sets them on the host so that the chaos monkey can select a namespace and pod on the current cluster. 

To add or remove a kubernetes cluster to the Chaos Monkey you need to follow those steps: 

#### Add a kuberentes cluster

1. Open the get_kubeconfig script
2. Navigate to the code line 29 / 30 with the *if then* statement
3. Copy and paste the line below and add this below to the  *if then* statement
```bash
$DOWNLOAD_DIR/doctl kubernetes cluster kubeconfig save <kubernets_cluster_name>
```
4. Save the file and run the Chaos Monkey application. You can also wait for the script to run automatically via the cronjob.

#### Add a kuberentes cluster
1. Open the get_kubeconfig script
2. Navigate to the code line 29 / 30 with the *if then* statement
3. Remove the line with the name of the Kubernetes cluster you want to delete, which looks like the following code segment
```bash
$DOWNLOAD_DIR/doctl kubernetes cluster kubeconfig save <kubernets_cluster_name>
```
4. Save the file and run the Chaos Monkey application. You can also wait for the script to run automatically via the cronjob.


### backup.sh
The backup script creates a backup of the Chaos Monkey log file every 24h and stores them in two separate locations (see list below). The current log file is cleaned up after the logs are backed up by the backup job. The script is triggered via a cronjob (**crontab -l**).
| Folder | Description |
|------|------|
|`"/data/chaos-monkey/backup/"` | Location to save the backup logs on the droplet itself. |
|`"/mnt/vlscmn_fra1_vol1/"` | Location to save the backup logs on a external DigitalOcean volume.  |


### automated_testing.sh
The automated test script is testing 5 different verry straight forward easy tests
- `"A001"`: Check Chaos-Monkey host
- `"A002"`: Call Chaos-Monkey application
- `"A003"`: Check Root ssh  login
- `"A004"`: Check Kubernetes cluster
- `"A005"`: Check demo applications

The test are running every night at 00:00 automatically and the output is located here: 
| File | Description |
|------|------|
|`"/data/chaos-monkey/test_error.log"` | If one of the tests will fail the result with the current date will paste the this file. |
|`"/data/chaos-monkey/test_output.log"` | The last run of the test is located here |
