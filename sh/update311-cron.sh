
# This script initializes an R script that updates the 311 dataset
# with new data (added daily) from NYC's data portal

# To shedule a cron job that runs this script automatically each day:
# (http://www.techradar.com/how-to/computing/apple/terminal-101-creating-cron-jobs-1305651)
# env EDITOR=nano crontab -e

cd /Users/simonejdemyr/dropbox/311
R CMD BATCH -q code/updateandaggregate311.R out.update311.txt

