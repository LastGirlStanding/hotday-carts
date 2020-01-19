**Build Resiliency into your Continuous Delivery Pipeline​ with AI and Automation** workshop given @[Dynatrace Perform 2020](https://https://www.dynatrace.com/perform-vegas//)

# Exercise 4: Modify pipeline to add automated load testing via jmeter
In this exercise we will configure our pipeline to include a jmeter performance test with a request attribute that is programmatically defined within the pipeline. We will also configure Dynatrace to capture this request attribute so that we can reference the load test requests from each pipeline execution with the Dynatrace API. 

1. Add request attributes to Dynatrace via the Dynatrace API:
    ```console
    cd /usr/keptn/hotday-carts/scripts
    ./createRequestAttributes.sh
    ```
1. Adjust pipeline to include performance tests:
    ```console
    cd /usr/keptn/hotday-carts
    cp .gitlab-ci-withperf.yml .gitlab-ci.yml
    git add .gitlab-ci.yml
    git commit -m "include performance tests"
    git push origin master
    ```