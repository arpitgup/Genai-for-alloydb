#!/bin/bash -eu
sudo apt update
#install postgres
sudo apt install -y postgresql postgresql-client postgresql-contrib
#exporting the password of Database
export PGPASSWORD="REPLACE-PASSWORD"
#create database 
psql -h REPLACE-PRIVATE-IP -U REPLACE-USERNAME -c "CREATE DATABASE REPLACE-DATABASE-NAME;"
#create extension for pg
psql -h REPLACE-PRIVATE-IP -U REPLACE-USERNAME -d REPLACE-DATABASE-NAME -c "CREATE EXTENSION IF NOT EXISTS vector;"
#enter in jupyter directory
cd /home/jupyter
#copy notebook from bucket to jupyter console
gsutil cp -r gs://REPLACE-BUCKET-NAME/GenAI_for_AlloyDB.ipynb .
gsutil cp -r gs://REPLACE-BUCKET-NAME/install_packages.ipynb .
#automation of executing .ipynb file
jupyter nbconvert --execute --to notebook install_packages.ipynb --output install_packages.ipynb
jupyter nbconvert --execute --to notebook GenAI_for_AlloyDB.ipynb --output GenAI_for_AlloyDB.ipynb