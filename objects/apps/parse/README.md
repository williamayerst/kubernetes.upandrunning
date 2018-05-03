# Parse Server
This solution requires MongoDB in the back end, created from the stateful set of MongoDB.

## Setup
Deploy the Mongo configuration, then deploy the service and deployment for Parse.

##Testing
Interact with it via REST API i.e. 

```bash
curl -X POST \
-H "X-Parse-Application-Id: my-app-id" \
-H "X-Parse-Master-Key: my-master-key-id" \
-H "Content-Type: application/json" \
-d '{"score":1337,"playerName":"Sean Plott","cheatMode":false}' \
http://localhost:1337/parse/classes/GameScore
```

You can get the item put by Parse back via REST like so: `curl -X GET -H "X-Parse-Application-Id: APPLICATION_ID" http://localhost:1337/parse/classes/GameScore/QQQQQQ`


