#!/bin/bash
#########################
# OpenFaaS Cheatsheet (macOS local development)
# 
# author: bryanchun
# This is cheatsheet for installing and getting started on
# using OpenFaaS, a serverless function-as-a-service software
# in conjunction with Docker and Kubernetes.
#########################

#########################
# Preliminaries
#########################
sysctl -a | grep -E --color 'machdep.cpu.features|VMX' 
                                        # check if virtualization is supported
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
                                        # install homebrew if you haven't
brew install docker                     # install docker if you haven't
open -a docker                          # and get docker running in background

#########################
# Installations
#########################
brew install minikube                   # minikube: runs Kubernetes locally - as a single-node cluster on a local VM
brew install kubectl                    # kubectl: is the cli for Kubernetes
brew install kubernetes-helm            # Helm: is the package manager for Kubernetes
curl -sL cli.openfaas.com | sudo sh     # faas-cli: is the cli for OpenFaas - this is the official installation command
curl -sLS https://dl.get-arkade.dev | sudo sh
                                        # k3sup: install helm charts (packages), including OpenFaaS, easier

#########################
# Hosting OpenFaaS (rerun in the beginning of each OpenFaaS session)
#########################
minikube start                          # starts a new Kubernetes local cluster
arkade install openfaas
kubectl port-forward svc/gateway -n openfaas 8080:8080 &
export OPENFAAS_URL=$(minikube ip):31112
PASSWORD=$(kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode; echo)
echo -n $PASSWORD | faas-cli login --username admin --password-stdin -g $OPENFAAS_URL
faas-cli list

"""
kubectl -n kube-system create sa tiller && kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
                                        # tiller: is the server side of Helm (helm is the client side)
                                        # create a service account for tiller
helm init --skip-refresh --upgrade --service-account tiller
                                        # tiller - install
kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
                                        # create namespaces in Kubernetes for OpenFaaS core components and functions
helm repo add openfaas https://openfaas.github.io/faas-netes/
                                        # add OpenFaaS to the helm repository
helm repo update                        # update all charts (packages on helm are called charts) on helm                                        
export PASSWORD=$(head -c 12 /dev/urandom | shasum | cut -d' ' -f1)
                                        # generate some random password
#echo $PASSWORD
kubectl -n openfaas create secret generic basic-auth --from-literal=basic-auth --user=admin --from-literal=basic-auth-password="$PASSWORD"
                                        # register a secret for the $PASSWORD, for logging into OpenFaaS later
helm upgrade openfaas --install openfaas/openfaas --namespace openfaas --set functionNamespace=openfaas-fn --set basic_auth=true
                                        # install OpenFaaS on Kubernetes using its chart
export OPENFAAS_URL=$(minikube ip):31112
                                        # set the OpenFaaS URL, which bases on the locally hosted IP on port 31112
echo -n $PASSWORD | faas-cli login -g http://$OPENFAAS_URL -u admin —-password-stdin
                                        # use the $PASSWORD to login to OpenFaaS at the gateway $OPENFAAS_URL
"""

#########################
# Checking if OpenFaaS is working
#########################
kubectl get pods -n openfaas            # check that the OpenFaaS Pod (unit of clustering in Kubernetes) is installed onto the cluster
# Browse to the URL `http://$OPENFAAS_URL/ui/` and you shall see a web UI

#########################
# Using OpenFaaS
#########################
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

# List the functions deployed
faas-cli list

# Check logs
func_name=hello-openfaas
kubectl logs deployment/$func_name -n openfaas-fn

# Check queue-worker logs
kubectl logs deployment/queue-worker -n openfaas

#########################
# Terminate and Teardown
#########################
minikube delete                     # everything will be deleted: Kubernetes and OpenFaaS

#########################
# Troubleshoot
#########################
# 1. If "Cannot connect to OpenFaaS on URL: http://127.0.0.1:8080", add gateway option `-g $OPENFAAS_URL`
# 2. Retrieve PASSWORD after log in
PASSWORD=$(kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode; echo)
echo $PASSWORD

# sed -n 30,51p cheatsheet.sh | sh
