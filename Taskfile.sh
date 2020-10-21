#!/bin/bash

function provision {
    terraform apply -var-file=azure-deploy.tfvars terraform
}

function destroy {
    terraform destroy -var-file=azure-deploy.tfvars terraform
}

function build {
    set -x DOCKER_HOST "tcp://0.0.0.0:2375"
    docker build -t zinefer/baphomet .
}

function push {
    docker push zinefer/baphomet
}

function help {
    echo "$0 <task> <args>"
    echo "Tasks:"
    compgen -A function | cat -n
}

TIMEFORMAT="Task completed in %3lR"
time ${@:-help}