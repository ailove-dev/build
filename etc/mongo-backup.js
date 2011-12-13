db.runCommand({fsync:1,lock:1}); // sync and lock
runProgram("rsync", "-avz", "--delete", "/var/lib/mongodb/", "/var/backups/mongodb/");
db.$cmd.sys.unlock.findOne(); //unlock

