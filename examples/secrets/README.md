# Secrets

To load a file into a secret you can use the following command: `kubectl create secret generic kuard-tls --from-file=kuard.crt --from-file=kuard.key`

An example of this secret in use is via `./secrets.yml` where the object is mounted to `/tls` for consumption inside the container.