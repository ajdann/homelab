cat .\butane.yaml | docker run --rm -i quay.io/coreos/butane:latest > ignition.json  
docker run --rm -v ${PWD}:/work -w /work quay.io/coreos/ignition-validate ignition.json
