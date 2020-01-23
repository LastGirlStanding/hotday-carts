**Build Resiliency into your Continuous Delivery Pipeline​ with AI and Automation** workshop given @[Dynatrace Perform 2020](https://https://www.dynatrace.com/perform-vegas//)

At this point we should have our initial setup complete. We should have a GKE cluster that is monitored by Dynatrace, a Gitlab runner capable of executing our pipeline jobs, and the full complement of Keptn services. 

# Exercise 2: Simple Gitlab pipeline to deploy Carts to Kubernetes
In this exercise we will configure our first [Gitlab](https://docs.gitlab.com/ee/ci/pipelines.html) CI/CD pipeline. Our simple pipeline will deploy the Carts microservice application to our Kubernetes cluster. This simple application emulates the functionality of a shopping cart via a Spring Boot application and a MongoDB datastore. If interested, the sourcecode for the Carts service is available [here](https://github.com/keptn-sockshop/carts).

Our pipeline will deploy both the application and the DB to each of the following environments, represented as separate namespaces in Kubernetes:
* Test
* Hardening
* Production

## Gitlab pipeline fundamentals
Our HOT day is not intended to be a comprehensive overview Gitlab pipelines but there are a number of elements that are noteworthy for our purposes today

1. Gitlab pipelines are composed in yaml and live alongside your codebase (*-as-Code)

1. Gitlab pipelines are made up of jobs that can be idempotent (wiped after use)

1. Gitlab pipeline jobs are arbitrary script commands that can be executed within arbitrary Docker containers that the are defined within the pipeline

1. Gitlab pipelines by are executed by default for each and every commit

1. Gitlab pipelines provide several environment variables that are automatically populated for us for each pipeline run

## Gitlab pipeline elements:
### Pipeline-wide environment variables

At the beginning of our pipeline we will define the global variables that our scripts will consume. Here we've defined the name of our application and the location of the kubeconfig we'll be populating in our subsequent jobs.
```console
variables:
  APPLICATION_SHORT_NAME: carts
  kubeconf_file: /tmp/kubeconf
```

### Pipeline stages
The stages of our pipeline represent the groups of jobs that will be executed in parallel. For example, all jobs with the stage "deploy-test" will occurr in parallel followed by all jobs with the stage "deploy-hardening" followed by jobs with the stage "deploy-production". By default the pipeline will not proceed to the next stage if any of the jobs fail (return a non-zero exit code) and the entire pipeline run will be marked as failed. 
```console  
stages:
  - deploy-test
  - deploy-hardening
  - deploy-production
```


### The Pipeline Job definition
Pipeline jobs represent the meat of our pipeline, where the actual work is occurring. Each job has several important elements

#### Job name, Docker image, and Environment
Here we are defining the "deploy-cartsdb-in-test" job which is executed within the devth/helm image tagged v2.12.3 on DockerHub. This job will execute as part of the deploy-test stage and within the carts-test environment. The value of "environment" automatically populates the "CI_ENVIRONMENT_SLUG" environment variable. 
```console  
deploy-cartsdb-in-test:
  image: docker.io/devth/helm:v2.12.3
  stage: deploy-test
  environment:
    name: carts-test
```
#### Job specific variables
Here we are setting an environment variable specific to the job. This block can be used to override global variables, if necessary. Here we're simply setting the value of GIT_STRATEGY to fetch rather than clone the git repo for the job. We're using a fetch here since they are quicker than a full clone.
```console  
  variables:
    GIT_STRATEGY: fetch
```
#### Job script
Here we define the script that will be executed within the Docker container. This script has a number of steps: 
1. alters the kubeconfig utilized by the Gitlab runner to be identical to the one we uploaded to Gitlab during environment setup
1. As we are utilizing Helm charts to represent our deployed application and Istio to manage ingress, we are using sed to change the vhost domain for the Istio ingress gateway to that used by Keptn
1. Executing a helm upgrade (which will install the chart if it doesn't exist or upgrade it if it does exist) and setting the Kubernetes namespace to be identical to the environment name. By specifying the --wait flag we ensure that the job does not finish unless the Helm command finishes.
```console  
  script:
    - echo ${kube_config} | base64 -d > ${kubeconf_file}
    - export KUBECONFIG=${kubeconf_file}
    - echo ${kube_config} | base64 -d > ${KUBECONFIG}
    - export KUBECONFIG=$KUBECONFIG
    - sed -i "s/REPLACEME/$(kubectl get cm -n keptn keptn-domain -ojsonpath={.data.app_domain})/g" charts/carts-db/values.yaml
    - helm upgrade
      carts-db-${CI_ENVIRONMENT_SLUG}
      --namespace=${CI_ENVIRONMENT_SLUG}
      --install
      --wait
      ./charts/carts-db/ 
```

#### Putting it all together, complete job definition:
```console  
#################################################################
# Deploy Stage
#################################################################
deploy-cartsdb-in-test:
  image: docker.io/devth/helm:v2.12.3
  stage: deploy-test
  environment:
    name: carts-test
  variables:
    GIT_STRATEGY: fetch
  script:
    - echo ${kube_config} | base64 -d > ${kubeconf_file}
    - export KUBECONFIG=${kubeconf_file}
    - echo ${kube_config} | base64 -d > ${KUBECONFIG}
    - export KUBECONFIG=$KUBECONFIG
    - sed -i "s/REPLACEME/$(kubectl get cm -n keptn keptn-domain -ojsonpath={.data.app_domain})/g" charts/carts-db/values.yaml
    - helm upgrade
      carts-db-${CI_ENVIRONMENT_SLUG}
      --namespace=${CI_ENVIRONMENT_SLUG}
      --install
      --wait
      ./charts/carts-db/ 
```


# Deploy our first Gitlab pipeline:
Our complete pipeline definition represents 6 jobs deploying carts and carts-db to each stage. The complete pipeline can be viewed [here](../.gitlab-ci-justdeploy.yml)

Please paste the following commands into your shell to make the pipeline change, commit it and push it via the git cli:
```console
cd /usr/keptn/hotday-carts
cp .gitlab-ci-justdeploy.yml .gitlab-ci.yml
git add .gitlab-ci.yml
git commit -m "simple deployment example"
git push origin master
```
Once this is complete, the pipeline should immediately begin executing:
  <img src="images/pipeline-running.png" width="50%">

  