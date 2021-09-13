# OmicApp

[![Docker](https://github.com/kstawiski/OmicApp/actions/workflows/docker.yml/badge.svg)](https://github.com/kstawiski/OmicApp/actions/workflows/docker.yml)

To do.

## Running application

GPU:

```
docker run -d --name testapp --gpus all --restart always -p 23424:80 -v /home/konrad/temp/testapp/:/home/app/ kstawiski/omicapp
```

CPU:

```
docker run -d --name testapp --restart always -p 23424:80 -v /home/konrad/temp/testapp/:/home/app/ kstawiski/omicapp-cpu
```

- `/home/konrad/temp/testapp/` - local directory where data is kept (persistance)
- `23424` - forwarded host port to the application
- `testapp` - name of the docker container

The default login credentials to `/developer` section is - user: `app`, password: `OmicSelector`. 
For production env remember to secure it by chaing the password: (change NEW_PASSWORD to your new strong one)

```
docker exec testapp bash -c "echo 'app:NEW_PASSWORD' | chpasswd"
```
