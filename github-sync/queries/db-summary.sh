echo "SELECT COUNT(*) as EventData FROM events;" | sqlite3 --header $1
echo "SELECT COUNT(*) as ReleaseData FROM releases;" | sqlite3 --header $1
echo "SELECT COUNT(*) as CommitData FROM commits;" | sqlite3 --header $1
echo "SELECT COUNT(*) as IssueData FROM issues;" | sqlite3 --header $1
echo "SELECT COUNT(*) as PullRequestData FROM pull_requests;" | sqlite3 --header $1
echo "SELECT COUNT(*) as PullRequestFileData FROM pull_request_files;" | sqlite3 --header $1
