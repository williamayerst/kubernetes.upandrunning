# Helm

Helm is a tool which obfuscates the need to configure all components of a Kubernetes oneself manually by using reusable blueprints called charts. These charts consist of a number of K8S objects, with sane defaults.

## Installation

Helm needs to either be defined to run as 'default', or have the tiller service account created to work:

```bash
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
```

Or, to use the default service account: `helm init --init --service-account default`

You can validate with `helm version`

## Deploying via Helm

Simply run `helm update` to update the local repository information, then `helm install stable/ZZZ`  - before you do that, `helm inspect` will allow you to review the configuration variables for a chart before it is deployed.

## Operation

`helm list` shows deployments. If you have done an upgrade (see below) then the revision counter will update. `helm delete --purge` will remove a chart.  when the helm chart is removed.

## Configuration and reconfiguration

If you want to change the configuration values via the command line, you can do so like so `helm install --set host=chat.yourdomain.com --set ingress.enabled=true stable/rocketchat`, or from an object `helm install -f vars.yml stable/rocketchat`.

If you wish to review any of the values you have set yourself, you can run `helm get values rocketchat`. If you've changed the values supplied in the file (or want to pipe more on the command line) you can use an `upgrade` command, such as `$ helm upgrade -f panda.yaml happy-panda stable/mariadb` - the previous command will upgrade the happy-panda release with a new configuration file.

The process by which changes are made to deployments for Helm (rather than any other mechanism) are via the configuration values above, in order to trigger revisions for roll-forward and roll-back.

## Authoring

 `helm create` will bootstrap a chart for your own usage. You can lint it with `helm lint` and then package with `helm package`, finally deploying with... `helm install -f vars.yml package.tgz`
