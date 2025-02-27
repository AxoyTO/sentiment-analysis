#!/bin/bash

# juju add-credentials azure
# juju default-region azure germany-west-central
juju bootstrap azure microk8s-controller

juju exec --unit microk8s/0 "sudo microk8s enable dns && sudo microk8s enable ingress && sudo microk8s enable hostpath-storage && sudo microk8s status --wait-ready"
#juju exec --unit microk8s/0 "sudo microk8s enable hostpath-storage"
#juju exec --unit microk8s/0 "sudo microk8s status --wait-ready"
juju exec --unit microk8s/0 "sudo usermod -a -G microk8s ubuntu && sudo chown -R ubuntu ~/.kube && newgrp microk8s"
juju exec --unit microk8s/0 "sudo snap alias microk8s.kubectl k"
juju scp k8s/fallback-deployment.yaml  microk8s/0:/home/ubuntu/
juju scp k8s/ingress.yaml  microk8s/0:/home/ubuntu/
juju scp k8s/proper-deployment.yaml  microk8s/0:/home/ubuntu/

mkdir ~/.kube
sudo usermod -a -G microk8s ubuntu
sudo chown -R ubuntu ~/.kube
newgrp microk8s
echo "alias k='microk8s kubectl'" >> ~/.bash_aliases
source ~/.bash_aliases
microk8s config > ~/.kube/config
