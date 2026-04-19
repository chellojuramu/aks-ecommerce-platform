# Roboshop on Kubernetes

Production-grade deployment of a microservices e-commerce application on Amazon EKS.

Built and deployed hands-on — every manifest written, debugged, and verified working end to end.

---

## What is Roboshop

Roboshop is a multi-service e-commerce platform (Stan's Robot Shop) with real microservices communicating over Kubernetes services using DNS-based service discovery.

---

## Architecture

```
Browser
   │
   ▼
AWS ELB (LoadBalancer)
   │
   ▼
frontend (nginx) :80
   │
   ├── /api/catalogue/ → catalogue:8080 → mongodb:27017
   ├── /api/user/      → user:8080      → mongodb:27017
   │                                    → redis:6379
   ├── /api/cart/      → cart:8080      → redis:6379
   │                                    → catalogue:8080
   ├── /api/shipping/  → shipping:8080  → cart:8080
   │                                    → mysql:3306
   └── /api/payment/   → payment:8080   → cart:8080
                                        → user:8080
                                        → rabbitmq:5672
```

---

## Services

| Service | Language | Image | Port | Dependencies |
|---|---|---|---|---|
| frontend | nginx | chelloju/roboshop-frontend:2.0 | 80 | all services |
| catalogue | Node.js | chelloju/roboshop-catalogue:2.0 | 8080 | mongodb |
| cart | Node.js | chelloju/roboshop-cart:2.0 | 8080 | redis, catalogue |
| user | Node.js | chelloju/roboshop-user:2.0 | 8080 | mongodb, redis |
| shipping | Java | chelloju/roboshop-shipping:2.0 | 8080 | cart, mysql |
| payment | Python | chelloju/roboshop-payment:2.0 | 8080 | cart, user, rabbitmq |
| mongodb | - | custom | 27017 | - |
| redis | - | redis:7.0 | 6379 | - |
| mysql | - | chelloju/roboshop-mysql:1.0 | 3306 | - |
| rabbitmq | - | rabbitmq:3 | 5672 | - |

---

## Kubernetes Concepts Used

- Deployments and ReplicaSets
- ConfigMaps for environment configuration
- Services — ClusterIP for internal, LoadBalancer for frontend
- Liveness, Readiness, and Startup Probes
- Resource Requests and Limits — Guaranteed QoS
- Volume Mounts — nginx.conf from ConfigMap
- Namespace isolation
- Labels and Selectors
- imagePullPolicy

---

## Folder Structure

```
k8-roboshop/
├── 01-namespace.yaml
├── mongodb/
├── redis/
├── mysql/
├── rabbitmq/
├── catalogue/
├── cart/
├── user/
├── shipping/
├── payment/
├── frontend/
└── debug/
```

Each folder contains a single YAML file with ConfigMap, Deployment, and Service defined together.

---

## Deploy Order

Dependencies must be running before services that need them:

```bash
# 1 — namespace
kubectl apply -f 01-namespace.yaml

# 2 — databases first
kubectl apply -f mongodb/
kubectl apply -f redis/
kubectl apply -f mysql/
kubectl apply -f rabbitmq/

# 3 — backend services
kubectl apply -f catalogue/
kubectl apply -f cart/
kubectl apply -f user/
kubectl apply -f shipping/
kubectl apply -f payment/

# 4 — debug pod
kubectl apply -f debug/

# 5 — frontend last
kubectl apply -f frontend/
```

---

## Verify Deployment

```bash
# check all pods are running
kubectl get pods -n roboshop

# check all services
kubectl get svc -n roboshop

# get frontend public URL
kubectl get svc frontend -n roboshop
# copy EXTERNAL-IP and open in browser
```

---

## Debugging

```bash
# exec into debug pod
kubectl exec -it debug -n roboshop -- bash

# test service connectivity
curl http://catalogue:8080/health
curl http://cart:8080/health
curl http://user:8080/health

# test port open
telnet mongodb 27017
telnet redis 6379
telnet rabbitmq 5672
```

---

## ConfigMap Update Flow

When you change a ConfigMap — always apply and restart:

```bash
kubectl apply -f <service>/
kubectl rollout restart deployment <service> -n roboshop
```

---

## Cluster Setup

Cluster created using eksctl on AWS EKS:

```bash
eksctl create cluster -f eksctl/eks.yaml
```

---

## Connect

Follow for more hands-on Kubernetes, Docker, AWS, and DevOps content:

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Ramu%20Chelloju-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/ramuchelloju/)