AFter enabling RBAC, set group system:serviceaccounts:kube-system to clusteradmin clusterrole


role groups are different (i.e. pods are in root rolegroup, deployments are in .extensions rolegroup)


`--use-service-account-credentials=true` on kube controller
api audit log

tail-f /var/log/kube-audit.log | grep -B1 -w '"403"'