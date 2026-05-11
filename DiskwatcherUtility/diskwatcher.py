import psutil 
import logging 
import signal
import sys

logging.basicConfig(
    filename='/var/log/diskwatcher.log',
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

def signal_handler(signum, frame):
    signame = signal.Signals(signum).name
    logging.info("Received signal %s, exiting...", signame)
    print ("Received signal #{} named {}, exiting...".format(signum, signame))
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)


def check_disk_usage(disk, min_critical, min_warning):


    disk_condition = psutil.disk_usage(disk)
    percent_free = round(100 - disk_condition.percent)


    if percent_free < min_critical:
        logging.critical("Critical: Low disk space on %s: Only %s%% free.", disk, percent_free)
        return "Critical: Low disk space on {}: Only {}% free.".format(disk, percent_free)
    elif percent_free < min_warning:
        logging.warning("Warning: Low disk space on %s: Only %s%% free.", disk, percent_free)
        return "Warning: Low disk space on {}: Only {}% free.".format(disk, percent_free)
    else:
        logging.info("Disk space on %s: %s%% free.", disk, percent_free)
        return "Disk space on {}: {}% free.".format(disk, percent_free)

if __name__ == "__main__":
    disk = "/"
    min_critical = 10  
    min_warning = 20   

    result = check_disk_usage(disk, min_critical, min_warning)
    print(result)

    