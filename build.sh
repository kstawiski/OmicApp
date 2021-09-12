#!/bin/bash
docker build -t omicapp .
docker tag omicapp:latest kstawiski/omicapp:latest
docker push kstawiski/omicapp