 # REDIS
 Redis is a distributed, in-memory key-value storing application. 


 # Get the master name, from one of the Pods
 kubectl exec redis-2 -c redis -- redis-cli -p 26379 sentinel get-master-addr-by-name redis

# Read a value from one of the replicas (redis-0 is the master, remember!)
 kubectl exec redis-2 -c redis -- redis-cli -p 6379 get foo

#### Reading

# Write a vlaue to one of the replicas (redis-0 is the master, remember!)
kubectl exec redis-2 -c redis -- redis-cli -p 6379 set foo 10
# Write a value to the master
kubectl exec redis-0 -c redis -- redis-cli -p 6379 set foo 10