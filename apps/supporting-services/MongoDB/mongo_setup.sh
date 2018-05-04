$ kubectl exec -it mongo-0 mongo

rs.initiate( {
  _id: "rs0",
  members:[ { _id: 0, host: "mongo-0.mongo:27017" } ]
 });


rs.add("mongo-2.mongo:27017");