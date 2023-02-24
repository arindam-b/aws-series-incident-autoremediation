#!/bin/bash

# Call env script to set shell and env
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

date

INSTANCE_ID_FILE="instance-id"
NAMESPACE="CustomNamespace"
REGION="us-east-1"

if test -f "$INSTANCE_ID_FILE"; then	
    echo "$INSTANCE_ID_FILE exist"
else
    # this will download file contains instance-id of current host
	wget http://169.254.169.254/latest/meta-data/instance-id
fi

INSTANCE_ID=$(cat instance-id)


count=$(ps aux | grep "webapp" | grep -v grep | wc -l)

aws cloudwatch put-metric-data \
    --metric-name "webapp-uptime" \
    --dimensions InstanceId=$INSTANCE_ID \
    --namespace $NAMESPACE \
    --value $count \
    --region $REGION


