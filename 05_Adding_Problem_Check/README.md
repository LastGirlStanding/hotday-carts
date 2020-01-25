**Build Resiliency into your Continuous Delivery Pipeline​ with AI and Automation** workshop given @[Dynatrace Perform 2020](https://https://www.dynatrace.com/perform-vegas//)

In our previous exercise, we added Dynatrace API calls to our pipeline notifying Dynatrace of deployment events. In this exercise, we will be adding a jmeter load test stage that occurs in the hardening stage. Additionally, our load test script will make use of the [x-dynatrace-test HTTP header](https://www.dynatrace.com/support/help/setup-and-configuration/integrations/third-party-integrations/test-automation-frameworks/dynatrace-and-load-testing-tools-integration/) and Dynatrace's [request attribute handling](https://www.dynatrace.com/support/help/how-to-use-dynatrace/transactions-and-services/basic-concepts/request-attributes/) so that we can identify our load test requests from within Dynatrace.

In our previous exercise, we added a load test to our pipeline. In this exercise, we will be adding a job to check DAVIS for problems in the hardening stage via a call to the [Dynatrace Problems API](https://www.dynatrace.com/support/help/extend-dynatrace/dynatrace-api/environment-api/problems/). This will allow us to automatically halt the pipeline before a deploy to production if a problem is detected in our hardening stage. 

# Exercise 5: Modify pipeline to automatically check Dynatrace before promoting release

## The Dynatrace Problems API: /api/v1/problem

### /api/v1/problem/feed request

While the Problems feed does not include any required fields we'll make use of a query parameter to query problems based on our hotday-tag-rule:

```console
curl -X GET "https://${DT_TENANT_URL}/api/v1/problem/feed?tag=hotday-tag-rule:${APPLICATION_SHORT_NAME}-${CI_ENVIRONMENT_NAME}" -H "Authorization: Api-Token ${DT_API_TOKEN}"
```

In the above example that is used by the pipeline job shown in full below, the tag query parameter is used to fetch problems containing the tag hotday-tag-rule with a value determined by our pipeline parameters.

Several other parameters exist, such as:

Parameter | type | Description
--- | --- | ---
relativeTime | string | The relative timeframe of the inquiry, back from the current time. i.e. "10mins" to query the last 10 minutes
startTimestamp | integer | The start timestamp of the requested timeframe, in UTC milliseconds.
endTimestamp | integer | The end timestamp of the requested timeframe, in UTC milliseconds. If this is greater than the current time, the current time is used. The total timeframe can't be over 31 days
status | string | Filters the result problems by the status. Accepted values are OPEN or CLOSED
impactLevel | string | Filters the result problems by the impact level. Accepted values are APPLICATION, ENVIRONMENT, INFRASTRUCTURE, or SERVICE

For the complete list and further details check the Problems API - Get feed [documentation](https://www.dynatrace.com/support/help/extend-dynatrace/dynatrace-api/environment-api/problems/problems/get-feed/)

### /api/v1/problem/feed response

The primary area of interest in the response body is the ProblemFeedQueryResult object (the "problems": [] part) within the ProblemFeedResultWrapper object (the "result": {} part). In the below example we have a problem array with only one element. In this example, there was an infrastructure problem with high connectivity failures on the "someprocessgroupname" process group. We can see that the problem was closed (so it is not ongoing) and it only impacted one piece of infrastructure which has since recovered. 

```json
{
  "result": {
    "problems": [
      {
        "id": "6637992734455503501_1579899780000V2",
        "startTime": 1579899780000,
        "endTime": 1579901102648,
        "displayName": "501",
        "impactLevel": "INFRASTRUCTURE",
        "status": "CLOSED",
        "severityLevel": "ERROR",
        "commentCount": 0,
        "tagsOfAffectedEntities": [
          {
            "context": "CONTEXTLESS",
            "key": "somekey",
            "value": "value"
          },
          {
            "context": "CONTEXTLESS",
            "key": "justatag"
          }
        ],
        "rankedImpacts": [
          {
            "entityId": "PROCESS_GROUP_INSTANCE-BE13DF5ADAAC13DD",
            "entityName": "someprocessgroupname",
            "severityLevel": "ERROR",
            "impactLevel": "INFRASTRUCTURE",
            "eventType": "HIGH_CONNECTIVITY_FAILURES"
          }
        ],
        "affectedCounts": {
          "INFRASTRUCTURE": 0,
          "SERVICE": 0,
          "APPLICATION": 0,
          "ENVIRONMENT": 0
        },
        "recoveredCounts": {
          "INFRASTRUCTURE": 1,
          "SERVICE": 0,
          "APPLICATION": 0,
          "ENVIRONMENT": 0
        },
        "hasRootCause": true
      }
    ],
    "monitored": {
      "INFRASTRUCTURE": 2009,
      "SERVICE": 48,
      "APPLICATION": 10,
      "ENVIRONMENT": 1
    }
  }
}
```

In the event of no problems, you would see an empty array for the problems object along with a count of monitored entities in the environment:

```json
{
  "result": {
    "problems": [],
    "monitored": {
      "INFRASTRUCTURE": 1549,
      "SERVICE": 32,
      "APPLICATION": 10,
      "ENVIRONMENT": 1
    }
  }
}
```

For the complete response details check the Problems API - Get feed [documentation](https://www.dynatrace.com/support/help/extend-dynatrace/dynatrace-api/environment-api/problems/problems/get-feed/)

## Pulling it all together

This job again makes use of the Dynatrace credentials stored in a config map to query the Problems API based on our hotday-tag-rule. It then processes the API response with jq and will fail our job if a problem is returned (i.e. the problems array is empty). Additionally, the job log will contain a link to the problem that can be copy/pasted into a browser for review. This job makes use of the delayed-start feature available in GitLab to start job execution 10 minutes after the previous job finishes. This allows DAVIS time to detect problems that may have occurred in the environment.

```yaml
dt_get_problems:
  stage: dynatrace-get-problems
  image: docker.io/mvilliger/keptn-k8s-runner:0.6.2
  variables:
      GIT_STRATEGY: none
  script: |
    echo ${kube_config} | base64 -d > ${kubeconf_file}
    export KUBECONFIG=${kubeconf_file}
    echo ${kube_config} | base64 -d > ${KUBECONFIG}
    export KUBECONFIG=$KUBECONFIG    
    DT_TENANT_URL=$(kubectl -n keptn get secret dynatrace-credentials-gitlab -ojsonpath={.data.dynatrace-credentials} | base64 -d | yq r - -d '*' DT_TENANT | cut -c 3-)
    DT_API_TOKEN=$(kubectl -n keptn get secret dynatrace-credentials-gitlab -ojsonpath={.data.dynatrace-credentials} | base64 -d | yq r - -d '*' DT_API_TOKEN | cut -c 3-)
    problems=$(curl -X GET "https://${DT_TENANT_URL}/api/v1/problem/feed?tag=hotday-tag-rule:${APPLICATION_SHORT_NAME}-${CI_ENVIRONMENT_NAME}" -H "Authorization: Api-Token ${DT_API_TOKEN}" | jq ".result.problems[0]")
    if [ "$problems" == "null" ]; then
      echo "No problem was found with your deployment."
    else
      problemid=$(echo $problems|jq -r .id)            
      echo "A problem was detected by Dynatrace!"
      echo "Problem ID:"
      echo $problems|jq .id
      echo $problems|jq .rankedImpacts[0]
      echo "A problem has been detected by Dynatrace, the problem can be viewed here: https://${DT_TENANT_URL}/#problems/problemdetails;pid=${problemid}"
      exit 1
    fi
  when: delayed
  start_in: 10 minutes  
```

# Making the changes to our pipeline

Adjust pipeline to include problem check via Dynatrace API:
```console
cd /usr/keptn/hotday-carts
cp .gitlab-ci-withproblemcheck.yml .gitlab-ci.yml
git add .gitlab-ci.yml
git commit -m "include problem check"
git push origin master
```