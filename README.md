# infrastructure

eval `ssh-agent -s`

ssh-add ~/.ssh/id_ed25519

export $(cat ../ansible/.ansible.env | xargs) && envsubst < headlamp-ingress.yaml | kubectl apply -f -

kubectl create token headlamp-admin -n kube-system
