Download der manifeste:
export VERSION=$(basename $(curl -s -w %{redirect_url} https://github.com/kubevirt/containerized-data-importer/releases/latest))
wget https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
wget https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml
