# Performance Troubleshooting

This lab was focused on practicing troubleshooting skills, specifically the ability to identify the root of performance degradation of the system using **USE method** (Utilization, Saturation, Errors). Lab included 3 different scenarios, where using `stress-ng` utility, each was aiming to load specific part of the system.

> [!NOTE]
> Lab was completed considering that i didn't know which part of the system is under the stress test, so overall performance analysis was completed each time using USE method.


## Scenario 1 - CPU High Utilization

`stress-ng` command for the scenario 1 is:

```bash
stress-ng --cpu 4 --timeout 300s
```

Steps taken:
1. Firstly, i always start with `uptime` command to view load avarages for the past 1, 5, and 15 minutes, which showed that there is a load increse going right now, comparing 1 and 5 minute values.
![Screenshoot of terminal output for the `uptime` command used for scenario 1.](./assets/uptime_cpu.png)

2. Next, i checked system messages to check for error possibility which could cause a perforamnce issue. I used `dmesg -T | tail` command, which didn't show any error which could cause a perforamnce issue.

3. Using `vmstat 1` command-line tool i identified high utilization on the CPU from the 4 user-space processes.
![Screenshoot of terminal output for the `vmstat` command used for scenario 1.](./assets/vmstat_cpu.png)

4. To investigate deeper, i issued `pidstat 1` command to identify the PID of the processes and their command. `pidstat` showed 98%-99% utilization of all 4 cores of the CPU by ***stress-ng-cpu*** command/processes. 
![Screenshoot of terminal output for the `pidstat` command used for scenario 1.](./assets/pidstat_cpu.png)

5. To confirm that identified performance issue was affecting only CPU, next commands was issued to check other parts of the system:
```bash
iostat -xz --pretty 1
free -m
sar -n DEV 1
sar -n TCP,ETCP 1
htop
```
![Screenshoot of terminal output for the `htop` command used for scenario 1.](./assets/htop_cpu.png)

Commands didn't show any unusual activity in other parts of the system, so the `stress-ng-cpu` command/process was the only issue causing high CPU utilazation.

**Root Cause & Conclusion**</br>
Four ***stress-ng-cpu*** processes, one on each CPU (core), utilized all availbe CPU resources. Recommended to review the processes causing high CPU utilization, identify their purpose and set limits for the CPU resources available to them.


## Scenarion 2 - Memeory Saturation

`stress-ng` command used for this scenarion is:

```bash
stress-ng --vm 2 --vm-bytes 80% --timeout 300s
```

Steps taken:
1. By default, i checked the load averages using `uptime` command. It showed increase for the last minutes comapared to 5 and 10 minutes values.

2. Next, checked the system messages using `dmesg -T | tail` which was clear for the past 5 minutes 

3. Issued `vmstat 1` command and noticed swap out activity in the ***`so`*** column, which basically can be interpreted as *there is not enough physical memory to serve some processes*, so inactive data from RAM is moved to disk storage. 
![Screenshoot of terminal output for the `vmstat` command used for scenario 2.](./assets/vmstat_memory.png)

4. I checked RAM usage with `free -m` command, which showed that only ~300 MB of memory was free. This indicates that the system was experiencing high memory utilization, which could potentially lead to memory saturation. The combination of low free memory and swap out activity suggests that there was no immediatly available RAM resources to handle some processes.
![Screenshoot of terminal output for the `free` command used for scenario 2.](./assets/free_memory.png)

5. To explore the problem deeper, i check the disk utilization using `iostat -xz --pretty 1` command, to ensure that disk is working properly and would provide reliable swap space until RAM would be upgraded.
![Screenshoot of terminal output for the `iostat` command used for scenario 2.](./assets/iostat_memory.png)

6. With help of the `htop` utility, identified that two comands/processes ***stress-ng-vm*** were using memory resources the most.
![Screenshoot of terminal output for the `htop` command used for scenario 2.](./assets/htop_memory.png)

**Root Cause & Conclusion**</br>
Two ***stress-ng-vm*** processes put system under memory pressure, utilizing most of the available RAM. Kernel was forces to swap out inactive memory pages from RAM to disk to avoid crash due to the insufficient memory resources. Recommended to upgrade/increase RAM resources to to prevent the system from running out of usable memory or triggering an OOM.

