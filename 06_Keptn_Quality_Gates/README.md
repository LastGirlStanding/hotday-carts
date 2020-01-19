**Build Resiliency into your Continuous Delivery Pipeline​ with AI and Automation** workshop given @[Dynatrace Perform 2020](https://https://www.dynatrace.com/perform-vegas//)

# Exercise 6: Keptn Quality Gates recap and implementation within pipeline
In this exercise we will configure our pipeline to include Keptn Quality Gates. 

1. Enable Dynatrace SLI service for Keptn:
    ```console
    cd /usr/keptn/scripts
    ./enableDynatraceSLIforProject.sh gitlab
    kubectl apply -f ../manifests/dynatrace-sli-distributor.yaml
    kubectl apply -f ../manifests/dynatrace-sli-service.yaml    
    ```

1. Onboard Keptn project:
    ```console
    cd /usr/keptn/hotday-carts
    keptn create project gitlab --shipyard=./shipyard-standalone.yaml
    ```

1. Onboard Carts service to the gitlab Keptn project
    ```console
    cd /usr/keptn/hotday-carts
    keptn create service carts --project=gitlab
    ```

1. Add initial Service Level Objectives for Keptn to evaluate:
    ```console
    cd /usr/keptn/hotday-carts
    keptn add-resource --project=gitlab --service=carts --stage=hardening --resource=slo_quality-gates.yaml --resourceUri=slo.yaml
    ```

1. Adjust pipeline to include Keptn Quality Gates:
    ```console
    cd /usr/keptn/hotday-carts
    cp .gitlab-ci-full.yml .gitlab-ci.yml
    git add .gitlab-ci.yml
    git commit -m "include quality gates"
    git push origin master
    ```

1. Create calculated metrics for use by our Quality Gates:
    ```console
    cd /usr/keptn/hotday-carts/scripts
    ./create-calculated-metrics.sh CONTEXTLESS hotday-tag-rule carts-carts-hardening
    ```

1. Add Service Level Objectives that include calculated service mertics for Keptn to evaluate:
    ```console
    cd /usr/keptn/hotday-carts
    keptn add-resource --project=gitlab --service=carts --stage=hardening --resource=slo_quality-gates-extended.yaml --resourceUri=slo.yaml
    ```
