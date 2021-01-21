export CONTROL_PLANE_NAMESPACE=istio-system
export BOOKINFO_NAMESPACE=bookinfo
export BOOKINFO_MESH_USER=bookinfo-mesh-user
export BOOKINFO_APP_YAML=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/platform/kube/bookinfo.yaml
export BOOKINFO_DEST_RULES=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/destination-rule-all.yaml
export GATEWAY_CONFIG=https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/bookinfo-gateway.yaml


p "Installing the Red Hat Elasticsearch Operator"
pe "oc apply -n openshift-operators -f- <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: elasticsearch-subscription
  namespace: openshift-operators
spec:
  channel: '4.6'
  installPlanApproval: Automatic
  name: elasticsearch-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF"
pe ""
clear

p "Installing the Red Hat Jaeger Operator"
pe "oc apply -n openshift-operators -f- <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: jaeger-product-subscription
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: jaeger-product
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: jaeger-operator.v1.20.2
EOF"
pe ""
clear

p "Installing the Red Hat Kiali Operator"
pe "oc apply -n openshift-operators -f- <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: kiali-ossm
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: kiali-ossm
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: kiali-operator.v1.24.4
EOF"
pe ""
clear

p "Installing the Red Hat Service Mesh Operator"
pe "oc apply -n openshift-operators -f- <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: servicemeshoperator
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: servicemeshoperator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: servicemeshoperator.v2.0.1.1
EOF"
pe ""
clear

p "Create Control Plane Project"
pe "oc new-project $CONTROL_PLANE_NAMESPACE"
pe ""
clear

p "Create a Service Mesh Control Plane"
pe "oc apply -f- <<EOF
apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: basic
  namespace: ${CONTROL_PLANE_NAMESPACE}
spec:
  version: v2.0
  tracing:
    type: Jaeger
    sampling: 10000
  addons:
    jaeger:
      name: jaeger
      install:
        storage:
          type: Memory
    kiali:
      enabled: true
      name: kiali
    grafana:
      enabled: true
EOF"
pe ""
clear

p "Control Plane Installation Status"
pe "oc get smcp -n $CONTROL_PLANE_NAMESPACE"
pe ""
clear

p "Create a project for each Service Mesh Member"
pe "oc new-project $BOOKINFO_NAMESPACE"
pe ""
clear

p "Create a ServiceMeshMemberRoll resource"
pe "oc apply -n ${CONTROL_PLANE_NAMESPACE} -f- <<EOF
apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
  namespace: ${CONTROL_PLANE_NAMESPACE}
spec:
  members:
    # a list of projects joined into the service mesh
    - ${BOOKINFO_NAMESPACE}
EOF"
pe ""
clear

p "Create service mesh user"
pe "oc create user $BOOKINFO_MESH_USER"
pe ""
clear

p "Create mesh-user role binding"
pe "oc apply -n ${CONTROL_PLANE_NAMESPACE} -f- <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: ${CONTROL_PLANE_NAMESPACE}
  name: mesh-users
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: mesh-user
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: ${BOOKINFO_MESH_USER}
EOF"
pe ""
clear

p "Details Deployment"
pe "oc apply -n $BOOKINFO_NAMESPACE -f- <<EOF
apiVersion: v1
kind: Service
metadata:
  name: details
  labels:
    app: details
    service: details
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: details
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bookinfo-details
  labels:
    account: details
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: details-v1
  labels:
    app: details
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: details
      version: v1
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "true"
      labels:
        app: details
        version: v1
    spec:
      serviceAccountName: bookinfo-details
      containers:
      - name: details
        image: maistra/examples-bookinfo-details-v1:2.0.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
EOF"
pe ""
clear

p "Ratings Deployment"
pe "oc apply -n $BOOKINFO_NAMESPACE -f- <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ratings
  labels:
    app: ratings
    service: ratings
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: ratings
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bookinfo-ratings
  labels:
    account: ratings
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ratings-v1
  labels:
    app: ratings
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ratings
      version: v1
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "true"
      labels:
        app: ratings
        version: v1
    spec:
      serviceAccountName: bookinfo-ratings
      containers:
      - name: ratings
        image: maistra/examples-bookinfo-ratings-v1:2.0.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
EOF"
pe ""
clear

p "Reviews Deployment"
pe "oc apply -f- <<EOF
apiVersion: v1
kind: Service
metadata:
  name: reviews
  labels:
    app: reviews
    service: reviews
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: reviews
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bookinfo-reviews
  labels:
    account: reviews
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reviews-v1
  labels:
    app: reviews
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reviews
      version: v1
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "true"
      labels:
        app: reviews
        version: v1
    spec:
      serviceAccountName: bookinfo-reviews
      containers:
      - name: reviews
        image: maistra/examples-bookinfo-reviews-v1:2.0.0
        imagePullPolicy: IfNotPresent
        env:
        - name: LOG_DIR
          value: "/tmp/logs"
        ports:
        - containerPort: 9080
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: wlp-output
          mountPath: /opt/ibm/wlp/output
      volumes:
      - name: wlp-output
        emptyDir: {}
      - name: tmp
        emptyDir: {}
---
EOF"
pe ""
clear

p "Product Page Deployment"
pe "oc apply -n $BOOKINFO_NAMESPACE -f- <<EOF
apiVersion: v1
kind: Service
metadata:
  name: productpage
  labels:
    app: productpage
    service: productpage
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: productpage
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bookinfo-productpage
  labels:
    account: productpage
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: productpage-v1
  labels:
    app: productpage
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: productpage
      version: v1
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "true"
      labels:
        app: productpage
        version: v1
    spec:
      serviceAccountName: bookinfo-productpage
      containers:
      - name: productpage
        image: maistra/examples-bookinfo-productpage-v1:2.0.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
        volumeMounts:
        - name: tmp
          mountPath: /tmp
      volumes:
      - name: tmp
        emptyDir: {}
---
EOF"
pe ""
clear

p "Add Destination Rules"
pe "oc apply -n $BOOKINFO_NAMESPACE -f- <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage
spec:
  host: productpage
  subsets:
  - name: v1
    labels:
      version: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: ratings
spec:
  host: ratings
  subsets:
  - name: v1
    labels:
      version: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: details
spec:
  host: details
  subsets:
  - name: v1
    labels:
      version: v1
---
EOF"
pe ""
clear

p "List Pods"
pe "oc get pods -n $BOOKINFO_NAMESPACE"
pe ""
clear

p "List tool routes"
pe "oc get route -n $CONTROL_PLANE_NAMESPACE"
pe ""
clear

# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""