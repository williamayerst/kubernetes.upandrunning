# Kubernetes Administration

## Minikube
`minikube dashboard` launches Kubernetes UI
`curl $(minikube service ZZZ --url)` will curl the URL of the service ZZZ from your host machine
## KubeCTL
`kubectl proxy` launches API UI

### Config file with defaults:
$HOME/.kube/config

## Architecture
### Namespaces
kubectl --namespace=mystuff references objects in the mystuff namespace.

##### Change default namespace, use that namespace:
kubectl config set-context my-context --namespace=mystuff
kubectl config use-context my-context

### Objects
objects are stored as yml/json `kubectl apply -f obj.yml` and `kubectl delete -f obj.yml`


### Labels
`kubectl label pods hello-minikube color=yellow` will label the hello-minikube pod with "color=yellow" - you must force `--overwrite` and can remove with `-<LABEL>`

### Container Admin
Very similar to Docker : `kubectl exec`, `kubectl cp <ZZZ>:/src ./dest`, `kubectl logs`

## Pods
A Pod represents a collection of application containers and volumes running in the same execution environment. Pods, not containers, are the smallest deployable artifact in a Kubernetes cluster. This means all of the containers in a Pod always land on the same machine, share the same IP/port/hostname and can communicate directly.

Containers should be grouped into a pod if they need to land on the same host (i.e. web server and process that updates local files is same pod, web server and database is different pod)

### Deploying Imperatively
* `kubectl run xxx --image=yyy` is an  imperative command to run a pod in the cluster, it will automatically create a deployment step and add some randomised letters to the end.
* `kubectl get pods` will list pods in the namespace defined (or default)
* To remove, type `kubectl delete deployments/zzz` where `zzz` is the non-hashed part of the result of `get pods`

### Deploying Declaratively
See the Objects header above for using declarative configuration. 

#### Resource Utilisation
Resources are requested per container, not per Pod:

```
resources:
  requests:
    cpu: "500m"
    memory: "128Mi"
```

##### Memory
Kubernetes has no balloon driver so will terminate containers which hare running at higher memory utilisation than the limit

##### CPU
CPU requests are implemented using the cpu-shares functionality in the Linux kernel

#### Liveness and Readiness Checks
These are defined in the .yml, killing and restarting containers and not allowing them to come online without proper checks.

```
      livenessProbe:
        httpGet:
          path: /healthy
          port: 8080
        initialDelaySeconds: 5
        timeoutSeconds: 1
        periodSeconds: 10
        failureThreshold: 3
```

### Removing a pod
Note that there is a 30 second grace period when deleting a pod *after it stops recieving traffic* i.e. if there is an open HTTPS connection the pod will not be removed.

### Testing Pods
`kubectl port-forward ZZZ 8080:8080` will create a tunnel from your workstation's local port 8080 through the kubernetes master, to the kubernetes worker, to the pod, to a container instance.

`ALPACA_POD=$(kubectl get pods -l app=alpaca -o jsonpath='{.items[0].metadata.name}')` will generate a variable of just the specific deployment name
`kubectl port-forward $ALPACA_POD 48858:8080` will forward 48858 to :8080 on the pod queried above

### Storage
There are four types of storage:
* communication (for sharing data between containers in a pod)
* cache (for storing between container restarts)
* persistent (for storing between pod lifecycles)
* host (for direct access to /dev, etc.)
* remote volumes

These are defined in the volumes: section of the .yml file and are consumed by individual containers.

## Tracking Usage
### Labels
#### Adding
Deployments can be labelled:

```
kubectl run alpaca-prod --image=gcr.io/kuar-demo/kuard-amd64:1 --replicas=2 --labels="ver=1,app=alpaca,env=prod"
kubectl run alpaca-test --image=gcr.io/kuar-demo/kuard-amd64:2 --replicas=1 --labels="ver=2,app=alpaca,env=test"
kubectl run bandicoot-prod --image=gcr.io/kuar-demo/kuard-amd64:2 --replicas=2 --labels="ver=2,app=bandicoot,env=prod"
kubectl run bandicoot-staging --image=gcr.io/kuar-demo/kuard-amd64:2 --replicas=1 --labels="ver=2,app=bandicoot,env=staging"
```

or post-hoc `kubectl label deployments alpaca-test "canary=true"` - either way *it only affects deployments!* 

#### Selecting Pods
This can be done in the command line with `kubectl get pods --selector="ver=2"` or `kubectl get pods --selector="app=bandicoot,ver=2"` or `kubectl get pods --selector="app in (alpaca,bandicoot)"`

Or in a .yml file like so:

```
selector:
  matchLabels:
    app: alpaca
  matchExpressions:
    - {key: ver, operator: In, values: [1, 2]}
```

(the above will match all pods which have app=alpaca and ver=1 or ver=2)

### Annotations
Generic key/value pairs for free-form text, etc. but to be used sparely:

```
metadata:
  annotations:
    example.com/icon-url: "https://example.com/icon.png"
```
## Exposing Deployments
`kubectl expose deployment alpaca-prod` will expose an internal deployment

An internal DNS record of a pod in a kubernetes cluster will look like this `alpaca-prod.default.svc.cluster.local` (pod name, namespace, service, cluster name)