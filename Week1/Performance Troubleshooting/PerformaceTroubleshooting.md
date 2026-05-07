# Performance Troubleshooting

This lab was focused on practicing troubleshooting skills, specifically the ability to identify the root of performance degradation of the system using **USE method** (Utilization, Saturation, Errors). Lab included 3 different scenarios, where using `stress-ng` utility, each was aiming to load specific part of the system.

*Lab was completed considering that i didn't know which part of the system is under the stress test, so overall performance analysis was completed each time using USE method*


## Scenario 1 - CPU High Utilization

`stress-ng` command for the scenario 1 is:

```bash
stress-ng --cpu 4 --timeout 300s
```

Steps taken:
1. Firstly, i always start with `uptime` command to view load avarages for the past 1, 5, and 15 minutes, which showed that there is a load increse going right now, comparing 1 and 5 minute values.
2. Next, i checked system messages to check for **Error** possibility which could cause a perforamnce issue.I used `dmesg -T | tail` command, which didn't show any error which could cause a perforamnce issue.
3. Using `vmstat 1` command-line tool i identified high utilization on the CPU from the 4 user-space processes.
4. To investigate deeper, i issued `pidstat 1` command to identify the PID of the processes and their command. `pidstat` showed 98%-99% utilization of all 4 cores of the CPU by `stress-ng-cpu` command. 
5. To confirm that identified performance issue was affecting only CPU, next commands was issued to check other parts of the system:
```bash
iostat -xz --pretty 1
free -m
sar -n DEV 1
sar -n TCP,ETCP 1
htop
```
Commands didn't show any unusual activity in other parts of the system, so the `stress-ng-cpu` command/process was the only issue causing high CPU utilazation.

