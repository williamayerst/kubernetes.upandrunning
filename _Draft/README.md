# Draft

`draft create` - will create draft config (local .toml file) and `./charts` folder. The folder under 'templates' contains data for the helm chart. Those templates are using go syntax to set up the chart, and those value files/etc. Add secrets, etc. to customise the draft configuration.

Watch automates `draft up` commands.

annotation `"helm.sh/hook" : pre-install` in the yaml files will force helm to ensure this particular object is done before the others (`post-install` also valid)

valueform, secretKeyref (name/key) 

`draft up` will look at charts file, dockerfile, upload registry that draft was tied to (it also creates secret), then deploys pod (secret first, then deployment and service). It uses the current context! It can be used to build the dockerfile, deployment, etc. and subsequent delta changes on following runs.

`draft connect` will proxy to your app locally (like `kubectl port-forward` I guess?)

This will also create a Helm chart (`helm list`) and normal `helm` commands are available. `helm delete --purge` will remove the chart. You must ensure the objects created in the draft files have behaviour set correctly to delete/persist/etc. when the helm chart is removed.