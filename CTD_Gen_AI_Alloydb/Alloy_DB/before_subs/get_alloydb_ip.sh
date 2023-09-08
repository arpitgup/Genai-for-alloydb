#!/bin/bash

# Run the gcloud command and format the output as JSON
ip_address=$(gcloud beta alloydb instances describe REPLACE-INSTANCE-NAME --cluster=REPLACE-CLUSTER-NAME --region=us-central1 --format='value(ipAddress)')
echo "{\"ip_address\": \"$ip_address\"}"
