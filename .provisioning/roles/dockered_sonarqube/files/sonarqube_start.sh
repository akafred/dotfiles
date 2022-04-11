#!/bin/bash
if [ "$(docker ps -a -q -f name=sonarqube)" ]; then
  if [ $(docker inspect --format="{{ .State.Running }}" sonarqube) == "false" ]; then
    docker start sonarqube
  fi
else
  docker container run -d --name sonarqube -p "9000:9000" -p "9002:9092" -e "SONARQUBE_JDBC_USERNAME=sonar" -e "SONARQUBE_JDBC_PASSWORD=sonar" -e "SONARQUBE_JDBC_URL=jdbc:postgresql://host.lima.internal/sonar" mwizner/sonarqube:8.9.5-community -Dsonar.search.javaAdditionalOpts=-Dnode.store.allow_mmap=false
fi
