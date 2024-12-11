Download der manifeste:

# Point at latest release
export RELEASE=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)

wget https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml

wget https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml

Anzahl replicas für den operator auf 1 gesetzt, da eh nur eine node
