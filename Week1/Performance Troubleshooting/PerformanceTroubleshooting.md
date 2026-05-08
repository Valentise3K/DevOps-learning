
This lab focused on practicing troubleshooting skills, specifically identifying the root cause of system performance degradation using the **USE method**: Utilization, Saturation, and Errors. The lab included three different scenarios. In each scenario, the `stress-ng` utility was used to place load on a specific part of the system.

> [!NOTE]
> The lab was completed without prior knowledge of which system resource was under stress. Because of that, the overall performance analysis was completed each time using the USE method.


## Scenario 1 - CPU High Utilization

The `stress-ng` command used for Scenario 1 was:

```bash
stress-ng --cpu 4 --timeout 300s
```

Steps taken:

1. First, I started with the `uptime` command to view the load averages for the past 1, 5, and 15 minutes. The output showed that the load was increasing, based on the comparison between the 1-minute and 5-minute values.
![Screenshot of terminal output for the `uptime` command used for Scenario 1.](./assets/uptime_cpu.png)

2. Next, I checked system messages for possible errors that could cause a performance issue. I used the `dmesg -T | tail` command, which didn't show any recent errors.

3. Using the `vmstat 1` command-line tool, I identified high CPU utilization caused by four user-space processes.
![Screenshot of terminal output for the `vmstat` command used for Scenario 1.](./assets/vmstat_cpu.png)

4. To investigate deeper, I issued the `pidstat 1` command to identify the PIDs and commands of the processes. `pidstat` showed 98%-99% utilization across all four CPU cores by the ***stress-ng-cpu*** processes.
![Screenshot of terminal output for the `pidstat` command used for Scenario 1.](./assets/pidstat_cpu.png)

5. To confirm that the identified performance issue was affecting only the CPU, I issued the following commands to check other parts of the system:

    ```bash
    iostat -xz --pretty 1
    free -m
    sar -n DEV 1
    sar -n TCP,ETCP 1
    htop
    ```
    ![Screenshot of terminal output for the `htop` command used for Scenario 1.](./assets/htop_cpu.png)
These commands didn't show unusual activity in other parts of the system, so the `stress-ng-cpu` processes were the main cause of high CPU utilization.

**Root Cause & Conclusion**  
Four ***stress-ng-cpu*** processes, one on each CPU core, utilized almost all available CPU resources. It is recommended to review the processes causing high CPU utilization, identify their purpose, and set CPU resource limits if necessary.


## Scenario 2 - Memory Saturation

The `stress-ng` command used for Scenario 2 was:

```bash
stress-ng --vm 2 --vm-bytes 80% --timeout 300s
```

Steps taken:

1. As the default first step, I checked the load averages using the `uptime` command. The output showed an increase in the latest (1-minute) load average compared to the previous values (5 and 15-minute).

2. Next, I checked system messages using the `dmesg -T | tail` command. The output didn't show any recent errors.

3. I issued the `vmstat 1` command and noticed swap-out activity in the ***so*** column. This indicates that the system was moving inactive memory pages from RAM to disk because there was not enough available physical memory for all running processes.
![Screenshot of terminal output for the `vmstat` command used for Scenario 2.](./assets/vmstat_memory.png)

4. I checked RAM usage with the `free -m` command, which showed that only about 300 MB of memory was free. This indicates that the system was experiencing high memory utilization, which could lead to memory saturation. The combination of low free memory and swap-out activity suggests that there were not enough immediately available RAM resources to handle all processes.
![Screenshot of terminal output for the `free` command used for Scenario 2.](./assets/free_memory.png)

5. To explore the problem deeper, I checked disk utilization using the `iostat -xz --pretty 1` command. This helped confirm whether the disk was handling swap activity properly and whether there were any disk performance issues.
![Screenshot of terminal output for the `iostat` command used for Scenario 2.](./assets/iostat_memory.png)

6. With the help of the `htop` utility, I identified that two ***stress-ng-vm*** processes were using the most memory resources.
![Screenshot of terminal output for the `htop` command used for Scenario 2.](./assets/htop_memory.png)

**Root Cause & Conclusion**  
Two ***stress-ng-vm*** processes put the system under memory pressure by utilizing most of the available RAM. The kernel was forced to swap out inactive memory pages from RAM to disk to prevent a crash caused by insufficient memory resources. It is recommended to increase RAM resources or limit the memory usage of these processes to prevent memory saturation or an OOM Killer process activation.


## Scenario 3 - Disk High Utilization & Saturation

The `stress-ng` command used for Scenario 3 was:

```bash
stress-ng --hdd 2 --timeout 300s
```

Steps taken:

1. My default first step was to check the load averages using the `uptime` command. The output showed an increase in the 1-minute load average compared to the 5 and 15-minute values.

2. Next, I checked system messages for possible errors using the `dmesg -T | tail` command, but it didn't show any recent errors.

3. I issued the `vmstat 1` command to get a more detailed look at system utilization. I noticed high activity in the ***I/O*** section, specifically in the ***block output*** column. Additionally, the ***b*** column, which represents processes blocked while waiting for I/O completion, showed 1 to 3 blocked processes. The ***wa*** column in the CPU section showed that 25%-75% of CPU time was spent waiting for outstanding disk I/O requests.
![Screenshot of terminal output for the `vmstat` command used for Scenario 3.](./assets/vmstat_disk.png)

4. The information from the previous step suggested disk saturation. To get more detailed information about disk utilization, I issued the `iostat -xz --pretty 1` command. The output showed that the ***sda*** disk was under about 95% utilization, with 65 MB/s of write activity and an average wait time of 683 milliseconds to serve a write request. This information suggests disk saturation caused by some process(es) running on the system.![Screenshot of terminal output for the `iostat` command used for Scenario 3.](./assets/iostat_disk1.png)

5. To identify the process saturating the disk, I issued the `htop` command, moved to the I/O table, and identified two ***stress-ng-hdd*** processes. These processes were generating heavy write activity and saturating disk performance.
![Screenshot of terminal output for the `htop` command used for Scenario 3.](./assets/htop_disk.png)

**Root Cause & Conclusion**  
Two ***stress-ng-hdd*** processes were utilizing the disk at about 95%, which led to high request wait time and disk saturation. It is recommended to review the processes causing disk saturation and either limit their disk usage or upgrade the system with higher-speed storage.