### Use Docker

NOTE: Experimental; feedback via GitHub issues much appreciated.

You can run oss-dashboard with Docker or docker-compose.

If you have already set up postgres server for `oss-dashboard`, you should run `oss-dashboard` by Docker.  
If you don't have any postgres server, you should run `oss-dashboard` by docker-compose.
docker-compose run `oss-dashboard` and postgres container at the same time.

#### Docker

```
  docker build -t oss-dashboard .
  docker run \
    -e GH_ACCESS_TOKEN=${GH_ACCESS_TOKEN} \
    oss-dashboard
```

If you configure dashboard/github settings, you write configuration files (`config-dashboard.yaml` and `config-github.yaml`) in this root dir.
(See [Setup section](https://github.com/amzn/oss-dashboard#setup) about the contents of configuration files)

Then execute the following commands.

```
  docker build -t oss-dashboard .
  docker run \
    -v $PWD/config-dashboard.yaml:/oss-dashboard/config-dashboard.yaml \
    -v $PWD/config-github.yaml:/oss-dashboard/config-github.yaml \
    -v $PWD/data:/oss-dashboard/data \  # if you need data files (specified `data-directory`), you need this line.
    -v $PWD/html:/oss-dashboard/html \  # if you need html files (specified `www-directory`), you need this line.
    oss-dashboard refresh-dashboard.rb --ghconfig config-github.yaml config-dashboard.yaml
```

If you connect to your organization's GitHub Enterprise, you must specify your GitHub Enterprise API endpoint to `OCTOKIT_API_ENDPOINT`.

```
  docker run \
    -v $PWD/config-dashboard.yaml:/oss-dashboard/config-dashboard.yaml \
    -v $PWD/config-github.yaml:/oss-dashboard/config-github.yaml \
    -e OCTOKIT_API_ENDPOINT=https://github.mycompany.com/api/v3/ \
    oss-dashboard refresh-dashboard.rb --ghconfig config-github.yaml config-dashboard.yaml
```

#### Docker Compose

Before running `oss-dashboard` by docker-compose, you need to prepare `config-dashboard.yaml` (and `config-github.yaml` if you need) in root dir.  
Then you run the following command.

```
docker-compose up
```

If you need to use `config-github.yaml` (see [Setup section](https://github.com/amzn/oss-dashboard#setup)), you rewrite `docker-compose.yml` as follows and execute `docker-compose up` command.

```
(snip)
    command: refresh-dashboard.rb --ghconfig config-github.yaml config-dashboard.yaml  # Add `--ghconfig` option
    volumes:
       - ./config-dashboard.yaml:/oss-dashboard/config-dashboard.yaml
       - ./config-github.yaml:/oss-dashboard/config-github.yaml   # Stop commentting out
(snip)
```
