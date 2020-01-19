# Exercise 5: Modify pipeline to automatically check Dynatrace before promoting release
In this exercise we will configure our pipeline to check Dynatrace for problems via an API request. 

1. Adjust pipeline to include problem check via Dynatrace API:
    ```console
    cd /usr/keptn/hotday-carts
    cp .gitlab-ci-withproblemcheck.yml .gitlab-ci.yml
    git add .gitlab-ci.yml
    git commit -m "include problem check"
    git push origin master
    ```