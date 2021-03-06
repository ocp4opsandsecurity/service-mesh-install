# service-mesh-features
This exercise explores many of the powerful Service Mesh features covered in the Istio BookInfo reference application.

The Bookinfo application consists of these microservices:

- The _productpage_ microservice calls the details and reviews microservices to populate the page.
- The _details_ microservice contains book information.
- The _reviews_ microservice contains book reviews. It also calls the ratings microservice.
- The _ratings_ microservice contains book ranking information that accompanies a book review.

There are three versions of the _reviews_ microservice:

- Version v1 does not call the _ratings_ Service.
- Version v2 calls the _ratings_ Service and displays each rating as one to five black stars.
- Version v3 calls the _ratings_ Service and displays each rating as one to five red stars.

> Use the [Quick-Start](#quick-start) to configure environment variables and the service mesh deployment.

- [Assumptions](#assumptions)
- [Traffic Management](#traffic-management)
- [Walk-Through](#walk-through)
- [Quick-Start](#quick-start)
- [References](#references)

## Assumptions
1. Clone the service mesh project using the following command.
```bash
git clone https://github.com/ocp4opsandsecurity/service-mesh.git
```

2. Make the service-mesh directory current working directory using the following command:
```bash
cd service-mesh
```  

3. Red Hat OpenShift Service Mesh is installed and configured using the [Quick-Start](#quick-start) or the procedure as 
described in the [Service Mesh Install](../install/how-to.md) how-to.
   
4. **Note** `Curl` and `Pipe Viewer` are to be installed on your system.

## Verify Deployment

1. List the running `Pods` using the following command:
```bash
oc get pods -n bookinfo
```

2. List the `Tools` routes using the following command:
```bash
oc get route -n istio-system
```   

3. List the `Gateway` URL using the following command:
```bash
export GATEWAY_URL=$(oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')
```

4. On the **http://${GATEWAY_URL}/productpage** of the Bookinfo application, refresh the browser.
```bash
echo http://${GATEWAY_URL}/productpage
```

You should see that the traffic is routed to the v1 services.

> An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!
> - Reviewer1

> Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.
> - Reviewer2

## Traffic Management
Traffic routing lets you control the flow of traffic between service versions.

### Request Routing
Request routing by defaults routes traffic to all available service versions in a round-robin fashion. 

1. Deploy `Reviews v2` virtual service using the following commands:
```bash
oc apply -f ./traffic-management/virtual-service-reviews-v2.yaml
```

On the **/productpage** of the bookinfo application, refresh the browser. You should see that traffic is routed to the V2
services with `BLACK Stars`.

2. Send some traffic using the following command:
```bash
for i in {1..20}; do sleep 0.25; curl -I http://${GATEWAY_URL}/productpage; done
```

3. Deploy `reviews v3` virtual service until you see RED star reviews using the following commands:
```bash
oc apply -f ./traffic-management/virtual-service-reviews-v3.yaml
```

On the **/productpage** of the bookinfo application, refresh the browser. You should see that traffic is routed to the V3 
services with `RED Stars`.

4. Send some traffic using the following command:
```bash
for i in {1..20}; do sleep 0.25; curl -I http://${GATEWAY_URL}/productpage; done
```

### Load Balancing
Round-robin is the default load balancing policy, where each service instance in the instance pool gets a request in turn.

Supported load balancing policy models:
- **Random:** Requests are forwarded at random to instances in the pool.
- **Weighted:** Requests are forwarded in the pool according to a specific percentage.
- **Least requests:** Requests are forwarded to the instances with the least number of requests.

1. **Weighted** example routes the bulk of the review traffic to version `v1` with the balance routed to `v3` using the following command:
```bash
oc apply -f ./traffic-management/weighted-v1-99-v3-1.yaml
```

On the /productpage of the bookinfo application, refresh the browser. You should see that traffic is routed to the V3
services with `99% No Stars` and `1% RED Stars`.

4. Send some traffic using the following command:
```bash
for i in {1..1000}; do sleep 0.25; curl -I http://${GATEWAY_URL}/productpage; done
```

#### Header Based Routing
We can change the route configuration so that all traffic from a specific user is routed to a specific service 
version. In this case, all traffic from a user named `Bill` will be routed to the service reviews:v2 and from user named
`Fred` will be routed to the service _reviews:v1_. This example is enabled by the fact that the _productpage_ service adds 
a custom end-user header to all outbound HTTP requests to the _reviews_ service.

1. Deploy the _reviews_ `VirtualService` that matches on `Bill` or `Fred` using the following command:
```bash
oc apply -f ./traffic-management/headers-bill-fred.yaml
```

2. On the **/productpage** of the Bookinfo application, log in as user `Bill`. Refresh the browser. What do you see? 
The BLACK star ratings appear next to each review.

3. On the **/productpage** of the Bookinfo application, log in as user `Fred`. Refresh the browser. What do you see?
The RED star ratings appear next to each review.

4. Log in as another user (pick any name you wish). Refresh the browser; notice the stars are gone! This is because 
traffic is routed to _reviews:v1_ for all users except Bill and Fred.
   
## Walk-Through
Use this walk-through as an automated guide explore Red Hat Service Mesh features based on the Istio BookInfo reference 
application. 

1. Execute the walk-through using the following command:
```bash
sh ./traffic-management/walk-through.sh
```

## Quick-Start
Use this `quick-start` to install, deploy, and configure this how-to for Red Hat OpenShift Service Mesh so that your can
explore the tools and get right to it.

1. Execute the quick-start using the following command:
```bash
sh ./install/quick-start.sh
```

## References
- [Demo Magic](https://github.com/paxtonhare/demo-magic)
- [Istio Release 1.6.14](https://istio.io/latest/news/releases/1.6.x/announcing-1.6.14/)
- [Red Hat OpenShift Command Line Tools](https://docs.openshift.com/container-platform/4.6/cli_reference/openshift_cli/getting-started-cli.html#cli-about-cli_cli-developer-commands)
- [Red Hat Service Mesh](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.6/html-single/service_mesh/index)
- [Unable To Delete Project](https://access.redhat.com/solutions/4165791)
