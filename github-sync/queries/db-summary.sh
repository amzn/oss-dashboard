echo "SELECT COUNT(*) as EventData FROM events;" | sqlite3 --header db/gh-sync.db
echo "SELECT COUNT(*) as ReleaseData FROM releases;" | sqlite3 --header db/gh-sync.db
