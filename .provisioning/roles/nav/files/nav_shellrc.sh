
# så lenge man er i riktig context kan man f.eks. kjøre port_forward helse-spion-frontend og nå den fra localhost:8080
port_forward() {
  TARGET=$(echo $(kubectl get pods | grep "^$1-" -m 1 | cut -d' ' -f1))
  CONTAINER_PORT=$(kubectl get pod $TARGET --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}')
  kubectl port-forward pods/$TARGET 8080:$CONTAINER_PORT
}
