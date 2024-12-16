# Basic converter from DeploymentConfig to Deployment

## Table of Content

1) Table of content
2) What is
3) Prerequisites
2) Usage

## What is
This simple script can be used to convert a DeploymentConfit to a Deployment.
It works using `yq` to delete and convert specific fields

## Prerequisites
In order to use this script you must ensure that `yq` is already installed in your local machine and all the files you want to convert are available in a directory or subdirectory where the script will run.
It is possible to edit the working folder by editing the `source_path` variable at the beginning of the script itself.

## Usage
As per prerequisites, download this script in the folder where you store all your deploymentConfig. \
Run the script like `convert_deploymentconfig_to_deployment.sh`.

A full scan of the current folder and all subfolders will be performed and for each deploymentConfig a new Deployment will be created.
Even a basic check will be perfomed by `oc apply -f --dry-run=server $deployment`.


