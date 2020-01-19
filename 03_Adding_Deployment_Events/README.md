**Build Resiliency into your Continuous Delivery Pipeline​ with AI and Automation** workshop given @[Dynatrace Perform 2020](https://https://www.dynatrace.com/perform-vegas//)

# Exercise 3: Modify pipeline to automatically push deployment events to enhance DAVIS root cause analysis
In this exercise we will configure our pipeline to include Dynatrace deployment events. These events will enrich the DAVIS root cause analysis engine and provide trackback to our pipelines from within Dynatrace.

```console
cd /usr/keptn/hotday-carts
cp .gitlab-ci-withevents.yml .gitlab-ci.yml
git add .gitlab-ci.yml
git commit -m "include Deployment events"
git push origin master
```
