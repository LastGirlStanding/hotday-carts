**Build Resiliency into your Continuous Delivery Pipeline​ with AI and Automation** workshop given @[Dynatrace Perform 2020](https://https://www.dynatrace.com/perform-vegas//)

# Exercise 2: Simple Gitlab pipeline to deploy Carts to Kubernetes
In this exercise we will configure our first [Gitlab](https://docs.gitlab.com/ee/ci/pipelines.html) CI/CD pipeline. This simple pipeline will deploy the Carts service to three stages:
* Test
* Hardening
* Production

```console
cd /usr/keptn/hotday-carts
cp .gitlab-ci-justdeploy.yml .gitlab-ci.yml
git add .gitlab-ci.yml
git commit -m "simple deployment example"
git push origin master
```

