## stacks

These are Docker stack definitions in docker-compose format. Each
represents a separate service running in Swarm.

### Notes

* If this repo contains a custom image definition published to Docker
  hub, its stack definition is sym-linked to the docker-compose.yml
  file in the same directory as its Dockerfile

* Environment variables, labels and external secrets are local
  settings which are kept in a separate private git repo. They're each
  referenced explicitly in the environment section of each compose
  file, rather than by reference to a separate env_file, for
  clarity.

|ADMIN_PATH|Directory (stored in git) containing admin settings|
|DB_HOST|Load-balanced hostname of primary MySQL database|
|REGISTRY_URI|Local docker registry hostname:port|
|SHARE_PATH|Directory pathname to synchronize across hosts|
