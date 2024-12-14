clone and set .env variables.
run ephemeral container to generate keys


```bash
docker compose run --rm --entrypoint /bin/bash node
```

inside the container run:

```bash
fuel-core-keygen new --key-type peering
```

save keys somewhere safe
then exit and run the node

```bash
docker compose up -d
```
