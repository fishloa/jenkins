# jenkins

Custom Jenkins LTS image for `ci.icomb.place`.

Extends `jenkins/jenkins:lts` with the toolchain the zenith Jenkinsfile expects on the controller:

| Tool      | Why                                                           |
| --------- | ------------------------------------------------------------- |
| `python3` | `scripts/test_find_redundant.py`, `scripts/coverage-diff.py` (PR #473, #472 / zenith) |
| `bun`     | `bun install`, `bun run lint:fetch`, `make contracts-check`   |
| `jq`      | Generally useful in pipeline `sh` steps                       |
| `make`    | `make contracts-check`                                        |
| `unzip`   | Required by the bun installer                                 |

The Docker CLI is not installed here — the existing docker-compose mounts the host's `/usr/bin/docker` (and `cli-plugins`) read-only into the container, which is the standard "docker-outside-of-docker" pattern for Jenkins agents that need to build images.

## Build

CI publishes to `ghcr.io/fishloa/jenkins:latest` on every push to `main`. To build locally:

```bash
docker build -t ghcr.io/fishloa/jenkins:latest .
```

## Deploy

Replace the `image:` line in the Jenkins Portainer stack:

```yaml
services:
  jenkins:
    container_name: jenkins
    image: ghcr.io/fishloa/jenkins:latest   # ← was jenkins/jenkins:lts
    restart: unless-stopped
    group_add:
      - "999"
    ports:
      - '8001:8080'
      - '50000:50000'
    volumes:
      - jenkins:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/bin/docker:/usr/bin/docker:ro
      - /usr/libexec/docker/cli-plugins:/usr/libexec/docker/cli-plugins:ro
    environment:
      JAVA_OPTS: -Djava.awt.headless=true
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "5"

volumes:
  jenkins:
    external: true
```

The `jenkins` named volume keeps `/var/jenkins_home` (jobs, credentials, plugins) across image bumps.

## Updating

1. Edit `Dockerfile`, commit, push to `main`.
2. CI builds and pushes `ghcr.io/fishloa/jenkins:latest` + a sha-tagged image.
3. In Portainer, restart the Jenkins stack (or set up a webhook to pull `latest` on every push).
