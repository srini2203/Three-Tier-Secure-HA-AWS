# Kubernetes Week 1 — Fundamentals + Minikube

## What I Learned

- Pods
- Deployments
- ReplicaSets
- Services
- ClusterIP
- NodePort
- ConfigMaps
- Secrets
- Namespaces
- Labels and Selectors
- Self-Healing
- Docker + Kubernetes integration

## Architecture

```text
Python Flask Application
          |
          v
      Docker Image
          |
          v
       Minikube
          |
          v
     Deployment
          |
     ReplicaSet
          |
     +----+----+
     |         |
     v         v
   Pod 1     Pod 2
     |         |
     +----+----+
          |
          v
       Service
       NodePort
          |
          v
       Browser