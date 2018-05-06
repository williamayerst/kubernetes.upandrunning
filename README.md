# Kubernetes Notes

## Minikube

Minikube is a single node kubernetes cluster used for testing.

* `minikube start` launches the mini-kubernetes environment on a local machine. This must be run from the scame location your .minikube folder (i.e. home dir/drive) is located.
* `minikube dashboard` launches Kubernetes UI
* `curl $(minikube service ZZZ --url)` will curl the URL of the service ZZZ from your host machine

## KubeCtl

KubeCtl is the primary way in which you interact with the Kubernetes cluster via the command line. The API endpoints are available by running `kubectl proxy`.

### Config file with defaults

The configuration for Kubernetes (with such info as the default namespace) are located in `$HOME/.kube/config` - of particular interest is the public/private key pair used for authentication.

## Platform Architecture

The kubernetes environment consists of virtual nodes. These are coordinated through the use of system services (in the `kube-system` namespace) which handle scheduling of containers, internal traffic routing and so on.

## Internal Architecture

* Pods are groups of containers; these groups can be a single container, or a full stack; they can be replicated across nodes. They are typically only defined individually for testing, normally they are rolled up into higher order objects.

* Sets are groups of pods: stateful and replicasets are replicated across nodes, daemonsets are spread one to each node. They will keep the number of pods as declared in the event of container failure, node failure, etc. Normally, they are not defined individually and they are rolled up into higher order objects. It uses labels to identify the pods, and is itself identified by labels.

* Deployments are a way of controlling the updates of pods in sets; typically they embed replica/state/daemonset configuration and provide a trackable roll-out and roll-back point. (think: blue/green deployment).  It uses labels to identify the sets it creates, and is itself identified by labels.

* Services wrap a pod/deployment in an endpoint that can be consumed either internally or externally. They can also be used to define internal DNS names for external objects. It uses labels to identify the pods/deployments, and is itself identified by labels.

* Namespaces provide the top level organisation within the cluster for total segregation. The default namespace is `default`, if you wish to address/create/etc. objects in other namespaces, then you must specify that in the command explicitly ie.e. `kubectl --namespace=mystuff` references objects in the mystuff namespace. You can also more permanently change your namespace by running these commands `kubectl config set-context my-context --namespace=mystuff` and `kubectl config use-context my-context`

### Objects

All of the objects in Kubernetes can be declared either via command line or as YAML-formatted objects which are uploaded to the Kubernetes API via the `kubectl apply -f XXX` and `delete -f XXX` commands. You can replace existing configuration (if it's able to be replaced without wrecking what's there) with `kubectl replace -f nginx-deployment.yaml --save-config`.

### Labels

Labels are used BY kubernetes to loosely couple services together. A pod may have  `color=red` and the service will identify which pods to direct traffic to with a query for all `red` pods.

An example command is `kubectl label pods hello-minikube color=yellow`. This will label the hello-minikube pod with "color=yellow" - you must force `--overwrite` and can remove with `<LABEL>-`.

Deployments can be labelled: `kubectl run alpaca-prod --image=gcr.io/kuar-demo/kuard-amd64:1 --replicas=2 --labels="ver=1,app=alpaca,env=prod"`mor post-hoc `kubectl label deployments alpaca-test "canary=true"` - either way *it doesn't cascade!* or nodes `kubectl label nodes k0-default-pool-35609c18-z7tb ssd=true`

### Annotations

Annotations are NOT used by kubernetes, so are suitable for generic key/value pairs for free-form text, etc. but to be used sparely:

```yaml
metadata:
  annotations:
    example.com/icon-url: "https://example.com/icon.png"
```

## Pods

A Pod represents a collection of application containers and volumes running in the same execution environment. Pods, not containers, are the smallest deployable artifact in a Kubernetes cluster. This means all of the containers in a Pod always land on the same machine, share the same IP/port/hostname and can communicate directly.

Containers should be grouped into a pod if they need to land on the same host (i.e. web server and process that updates local files is same pod, web server and database is different pod)

You can't orchestrate containers individually, but you can interrogate them for logs and attach to them, etc. much like the Docker command line.: `kubectl exec`, `kubectl cp <ZZZ>:/src ./dest`, `kubectl logs`

### Deploying

One can simply create a pod on the fly and let at it - but this precludes the advantages that Kubernetes provides: there's no scheduling, no loadbalancing, etc. unless you also deploy other things. That said, it is a good way to test.  `kubectl run xxx --image=yyy` is an  imperative command to run a pod in the cluster, it will automatically hash out the name of the pod to ensure uniqueness. `kubectl get pods` will list pods in the namespace defined (or default).

Any imperative changes should be backed by .yml objects that are stored in version control!

#### Converting to Declarative YML objects

Any objects that are deployed imperatively can be converted like so `kubectl get deployment farts -o yaml > farts-deploy.yml` and then being sanitised.

#### Editing existing deployments

This can be performed directly on the configuration, like so: `$ kubectl edit deployment/alpaca-prod` will edit an existing deployment .yml file 'live'.

Alternatively, if the objects are deployed from .yml files, those files can be updated and a further `kubectl apply -f XXX` applied. It's worth noting that not all changes will provide a rollout or upgrade!

#### Resource Utilisation

When you are deploying your containers, you can set the level of resources each container in each pod can consume:

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

Get the name of the pod, and run `kubectl port-forward ZZZ 8080:8080` which would create a tunnel from your workstation's local port 8080 through the kubernetes master, to the kubernetes worker, to the pod, to a container instance. This is not the same as exposing the service!

### Storage

There are four types of storage:

* communication (for sharing data between containers in a pod)
* cache (for storing between container restarts)
* persistent (for storing between pod lifecycles)
* host (for direct access to /dev, etc.)
* remote volumes

These are defined either directly in the volumes: section of the .yml file or as separate volume, and volume-claim objects. Decoupling the volume from the pod definition is a good idea, because then you can change the config dynamically. Dynamic volumes can be provisioned by configuring `storage-class`  objects, and then referring to those - Kubernetes will then create your volume upon request in a service such as Azure.

## Sets

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

## Deployments

Pods manage contaniers, Replicasets manage Pods, Deployments manage ReplicaSets.

Note: A 'run' command creates a label on the pod of "run=ZZZ", which means it gets included in an auto-created ReplicaSet (which has a unique auto-created name as a label itself), and also into an auto-created Deployment. The Deployment as the 'highest order' object, controls the scale (for example)

The primary use of deployments as opposed to replicasets is twofold: Firstly, they are always created by default for you when you run a `kubectl run` command, and secondly because it allows you to stage the roll-out of updated containers into your pods across your environment.

Changes to a deployment yaml file (such as a new image, or change-cause being added) will cause a 'rollout', a staged change of the entire deployment/replicaset/pod - `kubectl get replicasets -o wide` is useful, as is `kubectl rollout history deployment ZZZ` or `kubectl rollout undo deployment ZZZ`

A recreate strategy will blow everything away by updating the replicaset, a rolling update will roll out the changes. You really need to use readiness checks with a rolling updates to manage maxunavailble/etc. There are default parameters for the minimum time per container to be waited for, and for a time-out between events in a deployment.

## Services

The `kubectl expose` command will wrap one of the existing objects into a service; using the same selector/port/etc. criteria as the object it's being performed against. If no type is specified it will be an internal-only ClusterIP service. See below for specific connectivity related information.

All services are available internally as service.namespace.svc.cluster.local - so a service in the default namespace should be able to talk to others by just their service name. An internal DNS record of a pod in a kubernetes cluster will look like this `alpaca-prod.default.svc.cluster.local` (pod name, namespace, service, cluster name)

To observe the containers inside a pod that are participating in the service, use `kubectl get endpoints alpaca-prod --watch`

You can also define an external service (`spec.type: externalname, spec.externalname: DNS`) which replaces the A-record and IP with a CNAME, so your containers think they are talking to a local service, but are infact going out to an external one. `external-ip-database` does something similar, but where you specify an IP rather than a name to create the CNAME entry for. *Kubernetes  can't check the health of external services!*

### Connectivity

See `https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0`

* A *ClusterIP* service is the default Kubernetes service. It gives you a service inside your cluster that other apps inside your cluster can access. There is no direct external access, but it can be accessed via `kubectl proxy` using `http://localhost:8080/api/v1/proxy/namespaces/<NAMESPACE>/services/<SERVICE-NAME>:<PORT-NAME>/`

* A *NodePort* service is the most primitive way to get external traffic directly to your service. NodePort, as the name implies, opens a specific port on all the Nodes (the VMs), and any traffic that is sent to this port is forwarded to the service. There are many downsides to this method: You can only have once service per port,  You can only use ports 30000–32767,  If your Node/VM IP address change, you need to deal with that.

* A *LoadBalancer* service is when K8S will leverage your cloud provider to stand up a SaaS loadbalancer on your behalf. This loadbalancer will have a dedicated IP. It gets expensive!

* An *Ingress* is another top level object, rather than a service. It can perform L7 loadbalancing, and so is mostly suitable for routing to multiple back-ends from a single IP address and being cost-concious.

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
