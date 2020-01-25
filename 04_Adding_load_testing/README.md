**Build Resiliency into your Continuous Delivery Pipeline​ with AI and Automation** workshop given @[Dynatrace Perform 2020](https://https://www.dynatrace.com/perform-vegas//)

In our previous exercise, we added Dynatrace API calls to our pipeline notifying Dynatrace of deployment events. In this exercise, we will be adding a jmeter load test stage that occurs in the hardening stage. Additionally, our load test script will make use of the [x-dynatrace-test HTTP header](https://www.dynatrace.com/support/help/setup-and-configuration/integrations/third-party-integrations/test-automation-frameworks/dynatrace-and-load-testing-tools-integration/) and Dynatrace's [request attribute handling](https://www.dynatrace.com/support/help/how-to-use-dynatrace/transactions-and-services/basic-concepts/request-attributes/) so that we can identify our load test requests from within Dynatrace.

# Exercise 4: Modify pipeline to add automated load testing via JMeter

## The x-dynatrace-test HTTP header

Following the best practices for configuring load testing tool integrations with Dynatrace, we'll be configuring jmeter to build out the x-dynatrace-test HTTP header with a series of key:value pairs.

### x-dynatrace-test HTTP header keys

Key | Description
--- | ---
LTN | The Load Test Name uniquely identifies a test execution (in our case, we'll be defining this dynamically based on the CI_COMMIT_SHA from Gitlab)
LSN | Load Script Name - name of the load testing script. This groups a set of test steps that make up a multi-step transaction (for example, an online purchase).
TSN | Test Step Name is a logical test step within your load testing script (for example, Login or Add to cart.)
VU | Virtual User ID of the unique virtual user who sent the request.

### Populating the x-dynatrace-test HTTP header with jmeter

To add dynamic variables to populate the header a BeanShell PreProcessor is added to the jmeter script. While this has already been done for you in the script present in this repo, here is the contents of the BeanShell script:

```java
import org.apache.jmeter.util.JMeterUtils;
import org.apache.jmeter.protocol.http.control.HeaderManager;
import java.io;
import java.util;

// -------------------------------------------------------------------------------------
// Generate the x-dynatrace-test header based on this best practice
// -> https://www.dynatrace.com/support/help/integrations/test-automation-frameworks/how-do-i-integrate-dynatrace-into-my-load-testing-process/
// -------------------------------------------------------------------------------------
String LTN=JMeterUtils.getProperty("DT_LTN");
if((LTN == null) || (LTN.length() == 0)) {
	if(vars != null) {
		LTN = vars.get("DT_LTN");
	}
}
if(LTN == null) LTN = "NoTestName";

String LSN = (bsh.args.length > 0) ? bsh.args[0] : "Test Scenario";
String TSN = sampler.getName();
String VU = ctx.getThreadGroup().getName() + ctx.getThreadNum();
String headerValue = "LSN="+ LSN + ";TSN=" + TSN + ";LTN=" + LTN + ";VU=" + VU + ";";

// -------------------------------------------
// Set header
// -------------------------------------------
HeaderManager hm = sampler.getHeaderManager();
hm.removeHeaderNamed("x-dynatrace-test");
hm.add(new org.apache.jmeter.protocol.http.control.Header("x-dynatrace-test", headerValue));
```

## Request Attributes for Load Testing

After adding the x-dynatrace-test header to our jmeter script we'll need to configure Dynatrace to capture and extract the values of the header. We'll be configuring the request attribute capture using the Dynatrace UI. For our purposes today we will only be using the LTN value from the header as our load test is quite simple.

The steps are as follows:
1. Navigate to Server-Side Service Monitoring -> Request Attributes
1. click "Define a new request attribute"
1. Define our request attribute with the name LTN
1. Data type should be string
1. capture the First value
1. leave the text as-is
1. add new data source
1. our data source will pull from all process groups, hosts, technologies and tags
1. the Request attribute source will be "HTTP request header"
1. capture on the server side of a web request
1. parameter name is x-dynatrace-test
1. Expand the "further restrict or process captured parameters"
1. Proprocess the paramater by extracting substring between LTN= and ;
1. select save.


## Pulling it all together

For this job, we're utilizing a lightweight Docker image built with just the necessary elements to interact with Kubernetes and execute a jmeter script. You can view the Dockerfile [here](https://github.com/akirasoft/jmeter-k8s-runner/blob/master/Dockerfile). Our job script pulls the istio vhost domain from the Keptn config map and utilizes the built-in GitLab environment variables to dynamically generate the URL for the system-under-test as well as populating the LoadTestName(LTN) value. 

```yaml
generate-load-in-hardening:
  image: docker.io/mvilliger/jmeter-k8s-runner:latest
  stage: load-hardening
  environment:
    name: carts-hardening
  variables:
    GIT_STRATEGY: fetch
  script:
    - echo ${kube_config} | base64 -d > ${kubeconf_file}
    - export KUBECONFIG=${kubeconf_file}
    - echo ${kube_config} | base64 -d > ${KUBECONFIG}
    - export KUBECONFIG=$KUBECONFIG
    - export DOMAIN=$(kubectl get cm -n keptn keptn-domain -ojsonpath={.data.app_domain})
    - jmeter -n -t ./jmeter/load.jmx
      -l ${CI_ENVIRONMENT_SLUG}_perf.tlf
      -JSERVER_URL="carts.${CI_ENVIRONMENT_SLUG}.${DOMAIN}"
      -JSERVER_PORT=80
      -JVUCount=10
      -JLoopCount=500
      -JThinkTime=250
      -JDT_LTN="PerfCheck_${CI_COMMIT_SHA}"
```

# Making the changes to our pipeline
   
Adjust pipeline to include performance tests:

```console
cd /usr/keptn/hotday-carts
cp .gitlab-ci-withperf.yml .gitlab-ci.yml
git add .gitlab-ci.yml
git commit -m "include performance tests"
git push origin master
```