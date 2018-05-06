# Ingress
Remember that you need to have an ingress controller running for this! `minikube addons enable ingress` for example! 

`https://medium.com/@Oskarr3/setting-up-ingress-on-minikube-6ae825e98f82`

`kubectl exec -it nginx-ingress-controller-95znp -n kube-system -- /nginx-ingress-controller --version`