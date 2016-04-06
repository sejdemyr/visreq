
# This script initializes an R script that updates the 311 dataset
# with new data (added daily) from NYC's data portal

# To shedule a cron job that runs this script automatically each day:
# (http://www.techradar.com/how-to/computing/apple/terminal-101-creating-cron-jobs-1305651)
# env EDITOR=nano crontab -e

# Use source rather than sh to run this script in order for module to work

module load r/3.2.1  
cd /afs/ir.stanford.edu/users/e/j/ejdemyr/WWW/data-vis/311
R CMD BATCH -q r/0-master.R out.update311.txt

