# faas

Instructions for using the serverless function-as-a-service (faas) tool OpenFaaS for the first time and some completed/attempted labs of workshops at https://github.com/openfaas/workshop, for documentation.

- Environment: macOS
- Purpose: Local development

### Preliminaries

``` bash
sysctl -a | grep -E --color 'machdep.cpu.features|VMX' 
                                        # check if virtualization is supported
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
                                        # install homebrew if you haven't
brew install docker                     # install docker if you haven't
open -a docker                          # and get docker running in background
```

### Installations

``` bash
brew install minikube                   # minikube: runs Kubernetes locally - as a single-node cluster on a local VM
brew install kubectl                    # kubectl: is the cli for Kubernetes
brew install kubernetes-helm            # Helm: is the package manager for Kubernetes
curl -sL cli.openfaas.com | sudo sh     # faas-cli: is the cli for OpenFaas - this is the official installation command
curl -SLsf https://get.k3sup.dev/ | sudo sh
                                        # k3sup: install helm charts (packages), including OpenFaaS, easier
```

### Hosting

Rerun this part every time restarting your OpenFaaS cluster

``` bash
minikube start                          # starts a new Kubernetes local cluster
k3sup app install openfaas              # install OpenFaaS in Helm
#sleep 3                                # may take a while to avoid "error: unable to forward port because pod is not running. Current status=Pending" and get the Pod (cluster) ready
kubectl port-forward svc/gateway -n openfaas 8080:8080 &
                                        # tunnel between local computer with the Kubernetes cluster
export OPENFAAS_URL=$(minikube ip):31112
PASSWORD=$(kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode; echo)                  # generate password for OpenFaaS and register it
echo -n $PASSWORD | faas-cli login --username admin --password-stdin -g $OPENFAAS_URL
                                        # login to OpenFaaS
faas-cli list                           # success check
```

### Usage

``` bash
faas-cli new --lang python3 hello-faas --prefix="<your docker hub username>"
faas-cli build -f hello-faas.yml    # rename to stack.yml to skip the -f flag
faas-cli push -f hello-faas.yml
faas-cli deploy -f hello-faas.yml
faas-cli up -f hello-faas.yml       # build && push && deploy
# Go to $OPENFAAS_URL/function/$function_name

# Show OpenFaaS dashboard
faas-cli dashboard

# Deploy a default set of functions
faas-cli deploy -f https://raw.githubusercontent.com/openfaas/faas/master/stack.yml

# Expose and use the monitoring board - Grafana
kubectl -n openfaas run \
    --image=stefanprodan/faas-grafana:4.6.3 \
    --port=3000 \
    grafana
kubectl -n openfaas expose deployment grafana \
    --type=NodePort \
    --name=grafana
GRAFANA_PORT=$(kubectl -n openfaas get svc grafana -o jsonpath="{.spec.ports[0].nodePort}")
GRAFANA_URL=http://$(minikube ip):$GRAFANA_PORT/dashboard/db/openfaas
kubectl port-forward deployment/grafana 3000:3000 -n openfaas

# List the functions deployed
faas-cli list

# Check logs
func_name=hello-openfaas
kubectl logs deployment/$func_name -n openfaas-fn

# Check queue-worker logs
kubectl logs deployment/queue-worker -n openfaas
```

### Troubleshooting

1. If error `Cannot connect to OpenFaaS on URL: http://127.0.0.1:8080` is shown, OpenFaaS cannot access its deafult IP address and needs redirection: add the gateway option `-g $OPENFAAS_URL` to all of your `faas-cli` commands
2. Retrieve PASSWORD after logging in

    ``` bash
    PASSWORD=$(kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password)" | base64 --decode; echo)
    echo $PASSWORD
    ```

### Terminate and Teardown

``` bash
kill %1                                 # kill off 'kubectl port-forward svc/gateway -n openfaas 8080:8080' (if it is still the first job)
minikube delete
```