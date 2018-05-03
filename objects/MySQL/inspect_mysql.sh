# Runs a container purely for the purpose of investigation:
kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -p password

# Enter into an existing mysql container using hte mysql commandline
kubectl exec -it mysql-648d67bf7c-n9fvz -- mysql -u root -p
