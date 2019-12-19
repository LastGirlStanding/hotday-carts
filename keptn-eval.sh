#!/bin/bash
# Log into keptn
# ${CI_ENVIRONMENT_SLUG}&tag=app:${APPLICATION_SHORT_NAME}
KEPTN_ENDPOINT=https://api.keptn.$(kubectl get cm keptn-domain -n keptn -ojsonpath={.data.app_domain})
KEPTN_API_TOKEN=$(kubectl get secret keptn-api-token -n keptn -ojsonpath={.data.keptn-api-token} | base64 -d)
keptn auth -a $KEPTN_API_TOKEN -e $KEPTN_ENDPOINT

# Start evaluation
ctxid=$(keptn send event start-evaluation --project=${APPLICATION_SHORT_NAME} --service=${APPLICATION_SHORT_NAME} --stage=${CI_ENVIRONMENT_SLUG} --timeframe=10m|tee tk|grep "context:"|awk {'print $5'})
cat tk

fin="0"
until [ "$fin" = "1" ]
do
    status=$(curl -s -k -X GET "${KEPTN_ENDPOINT}/v1/event?keptnContext=${ctxid}&type=sh.keptn.events.evaluation-done" -H "accept: application/json" -H "x-token: ${KEPTN_API_TOKEN}"|jq .data.evaluationdetails.indicatorResults[0].status)
    if [ "$status" = "null" ]; then
        echo "Status null will wait..."
        sleep 5
    else
        fin="1"
    fi
done
if [ "$status" = "\"fail\"" ]; then
        echo "Keptn Quality Gate - Evaluation failed!"
        echo "For details visit the Bridge!"
        exit 1
else
        echo "Keptn Quality Gate - Evaluation Succeeded"
fi
