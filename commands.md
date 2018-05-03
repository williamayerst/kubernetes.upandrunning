# Kubernetes Administration

## Minikube

Minikube is a single node kubernetes cluster used for testing.

* `minikube start` launches the mini-kubernetes environment on a local machine. This must be run from the scame location your .minikube folder (i.e. home dir/drive) is located.
* `minikube dashboard` launches Kubernetes UI
* `curl $(minikube service ZZZ --url)` will curl the URL of the service ZZZ from your host machine

## KubeCTL

`kubectl proxy` launches API UI

### Config file with defaults:

`$HOME/.kube/config`

## Architecture

### Namespaces

kubectl --namespace=mystuff references objects in the mystuff namespace.

#### Change default namespace, use that namespace

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

`$ kubectl edit deployment/alpaca-prod` will edit an existing deployment .yml file


#### Resource Utilisation

Resources are requested per container, not per Pod:

```yaml
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

```yaml
      livenessProbe:
        httpGet:
          path: /healthy
          port: 8080
        initialDelaySeconds: 5
        timeoutSeconds: 1
        periodSeconds: 10
        failureThreshold: 3
```

Another example would be using a command from an application inside the container itself, such as:

```yaml
 livenessProbe:
   exec:
     command:
     - /usr/bin/mongo
     - --eval
     - db.serverStatus()
   initialDelaySeconds: 10
   timeoutSeconds: 10
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

These are defined either directly in the volumes: section of the .yml file or as separate volume, and volume-claim objects. Decoupling the volume from the pod definition is a good idea, because then you can change the config dynamically. Dynamic volumes can be provisioned by configuring `storage-class`  objects, and then referring to those - Kubernetes will then create your volume upon request in a service such as Azure.

## Tracking Usage

### Labels

#### Adding

Deployments can be labelled:m`kubectl run alpaca-prod --image=gcr.io/kuar-demo/kuard-amd64:1 --replicas=2 --labels="ver=1,app=alpaca,env=prod"`mor post-hoc `kubectl label deployments alpaca-test "canary=true"` - either way *it doesn't cascade!*

or nodes `kubectl label nodes k0-default-pool-35609c18-z7tb ssd=true`

#### Selecting Pods

This can be done in the command line with `kubectl get pods --selector="ver=2"` or `kubectl get pods --selector="app=bandicoot,ver=2"` or `kubectl get pods --selector="app in (alpaca,bandicoot)"`

Or in a .yml file like so:

```yaml
selector:
  matchLabels:
    app: alpaca
  matchExpressions:
    - {key: ver, operator: In, values: [1, 2]}
```

(the above will match all pods which have app=alpaca and ver=1 or ver=2)

### Annotations

Generic key/value pairs for free-form text, etc. but to be used sparely:

```yaml
metadata:
  annotations:
    example.com/icon-url: "https://example.com/icon.png"
```

## Services

`kubectl expose deployment alpaca-prod` will create a service out of a deployment dy default internal-only A record and clustered IP. You can specify `--type=nodeport` to allow NATing into and out of your cluster to the service. This can also be achieved by changing the type in the object .yml file.  

It's also possible to define a service.yml file, which will expose a pod (using selectors).

An internal DNS record of a pod in a kubernetes cluster will look like this `alpaca-prod.default.svc.cluster.local` (pod name, namespace, service, cluster name)

To observe the containers inside a pod that are participating in the service, use `kubectl get endpoints alpaca-prod --watch`

You can also define an external service (spec.type: externalname, spec.externalname: <DNS>) which replaces the A-record and IP with a CNAME, so your containers think they are talking to a local service, but are infact going out to an external one. `external-ip-database` does something similar, but where you specify an IP rather than a name to create the CNAME entry for. *no healthcheckin!*


### ReplicaSets

ReplicaSets are objects which manage Pods of a given selector to the desired count/health. They use the `rs` command, i.e. `kubectl describe rs kuard`. To identify if a pod is managed by a replicaset, you can describe it to YAML and grep the kind/name from ownerreferences.

Deleting a ReplicaSet will automatically remove the pods unless `--cascade=false` is applied to the command.

#### Horizontal Pod Autoscaling (for CPU)

`kubectl autoscale rs kuard --min=2 --max=5 --cpu-percent=80` will automatically scale a pod based on when the allocated CPU goes over 80%. it is required that the kube-system namespace has a pod named heapster for this to work. !Don't mix manual and automatic replica management!

### DaemonSets

Daemonsets will automatically add a given pod to every node in the cluster

### StatefulSets

These are created and destroy sequentially, and will have a multiple DNS entries in the kubernetes DNS service instead of a clustered IP. See `.\statefulset` folder. One can set up volumeMounts persistent storage, but one must define a TEMPLATE for the claim, such as:

```yaml
  volumeClaimTemplates:
  - metadata:
      name: database
      annotations:
        volume.alpha.kubernetes.io/storage-class: anything
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 100Gi
```

## Jobs

Jobs are job-and-done deployments which do not automatically keep repopulating, i.e. database migration, work queue, etc.

`kubectl run -i oneshot --image=gcr.io/kuar-demo/kuard-amd64:1 --restart=OnFailure -- --keygen-enable --keygen-exit-on-complete --keygen-num-to-gen 10`

This can be defined as a YML file, but one will need to review the logs (rather than using an interactive terminal as in the above example to see the output)

Jobs can have parallelism and concurrency settings, and can be set to either terminate in place or be re-run when failed.

## ConfigMaps

To get data into a kubernetes Pod, ConfigMaps are a great tool. They are key-value pairs and/or text files that are ingested into a .yml object in the cluster. They can be used to define environment variables in a container, to be mounted as files inside the container, or in the command line for the container creation itself. See `./configmap/my-config.txt` for examples

Like many other objects it can be edited live: `kubectl edit configmap my-config`

## Secrets

K8S has native secret management, as so: `kubectl create secret generic kuard-tls --from-file=kuard.crt --from-file=kuard.key` and `kubectl describe secrets kuard-tls`. These are mounted like ConfigMaps as 'volumes' to paths inside containers in pods under the spec:

```yaml
  volumes:
    - name: tls-certs
      secret:
        secretName: kuard-tls
```

A shortcut to replace file-based secrets is like so `kubectl create secret generic kuard-tls --from-file=kuard.crt --from-file=kuard.key --dry-run -o yaml | kubectl replace -f -`

Private Docker Registries have a special secret, `kubectl create secret docker-registry` to create, and spec.imagePullSecrets to consume from within the object .yml.

## Deployments

Pods manage contaniers, Replicasets manage Pods, Deployments manage ReplicaSets. 

A 'run' command creates a label on the pod of "run=ZZZ", which means it gets included in an auto-created ReplicaSet (which has a unique auto-created name as a label itself), and also into an auto-created Deployment. The Deployment as the 'highest order' object, controls the scale (for example)

To save a deployment down to a file, run `kubectl get deployments nginx --export -o yaml > nginx-deployment.yaml` and then you can replace the extant deployment with one defined from that file using `kubectl replace -f nginx-deployment.yaml --save-config`

Changes to a deployment yaml file (such as a new image, or change-cause being added) will cause a 'rollout', a staged change of the entire deployment/replicaset/pod - `kubectl get replicasets -o wide` is useful, as is `kubectl rollout history deployment ZZZ` or `kubectl rollout undo deployment ZZZ`

A recreate strategy will blow everything away by updating the replicaset, a rolling update will roll out the changes. You really need to use readiness checks with a rolling updates to manage maxunavailble/etc. There are default parameters for the minimum time per container to be waited for, and for a time-out between events in a deployment.

