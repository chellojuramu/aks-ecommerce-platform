
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-3.0+-0F1689?logo=helm&logoColor=white)](https://helm.sh/)
[![Azure](https://img.shields.io/badge/Azure-AKS-0089D6?logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/en-us/services/kubernetes-service/)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)

> **Multi-tier microservices e-commerce platform deployed on Azure Kubernetes Service (AKS) using Helm charts**  
> Built with Node.js, Python, Java (Spring Boot), and nginx reverse proxy

---

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Detailed Installation](#-detailed-installation)
- [Configuration](#-configuration)
- [Accessing the Application](#-accessing-the-application)
- [Troubleshooting](#-troubleshooting)
- [Monitoring & Observability](#-monitoring--observability)
- [Production Best Practices](#-production-best-practices)
- [Cleanup](#-cleanup)
- [Contributing](#-contributing)
- [Author](#-author)

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Azure Application Gateway                   │
│                    (Ingress Controller - AGIC)                   │
│                      Public IP: 4.154.253.31                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Frontend (nginx)                          │
│                   Reverse Proxy on Port 8080                     │
│          Routes: /api/catalogue, /api/cart, /api/user, etc.     │
└──────────┬──────────────────────────────────────────────────────┘
           │
           ├──────────────────────────────────────────────────────┐
           │                                                       │
           ▼                          ▼                           ▼
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│   Catalogue      │      │      Cart        │      │      User        │
│   (Node.js)      │      │   (Node.js)      │      │   (Node.js)      │
│   Port: 8080     │      │   Port: 8080     │      │   Port: 8080     │
└────────┬─────────┘      └────────┬─────────┘      └────────┬─────────┘
         │                         │                         │
         ▼                         ▼                         ▼
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│    MongoDB       │      │      Redis       │      │    MongoDB       │
│  (Catalogue DB)  │      │  (Session Cache) │      │    (User DB)     │
│ StatefulSet/Dep  │      │   StatefulSet    │      │  StatefulSet/Dep │
└──────────────────┘      └──────────────────┘      └──────────────────┘

           ▼                          ▼
┌──────────────────┐      ┌──────────────────┐
│    Payment       │      │    Shipping      │
│   (Python)       │      │ (Java/Spring)    │
│   Port: 8080     │      │   Port: 8080     │
└────────┬─────────┘      └────────┬─────────┘
         │                         │
         ▼                         ▼
┌──────────────────┐      ┌──────────────────┐
│    RabbitMQ      │      │      MySQL       │
│ (Message Queue)  │      │  (Orders DB)     │
│   Deployment     │      │   Deployment     │
└──────────────────┘      └──────────────────┘
```

### 🎯 Service Breakdown

| Service | Runtime | Port | Purpose | Dependencies |
|---------|---------|------|---------|--------------|
| **Frontend** | nginx | 8080 | Reverse proxy & static content | All backend services |
| **Catalogue** | Node.js | 8080 | Product catalog management | MongoDB |
| **Cart** | Node.js | 8080 | Shopping cart operations | Redis, Catalogue |
| **User** | Node.js | 8080 | User authentication & profiles | MongoDB, Redis |
| **Payment** | Python | 8080 | Payment processing | RabbitMQ, Cart, User |
| **Shipping** | Java/Spring Boot | 8080 | Order shipping & tracking | MySQL, Cart |
| **MongoDB** | Database | 27017 | Document store (Catalogue, User) | - |
| **Redis** | Cache | 6379 | Session cache & temporary data | - |
| **MySQL** | Database | 3306 | Relational data (Orders, Shipping) | - |
| **RabbitMQ** | Message Queue | 5672 | Asynchronous messaging | - |

---

## 💻 Tech Stack

### **Application Services**
- **Node.js** (v16) - Catalogue, Cart, User
- **Python** (v3.9) - Payment
- **Java** (Spring Boot 2.x) - Shipping
- **nginx** (1.23) - Frontend reverse proxy

### **Infrastructure**
- **MongoDB** (5.0) - NoSQL database
- **Redis** (7.0) - In-memory cache
- **MySQL** (8.0) - Relational database
- **RabbitMQ** (3-management-alpine) - Message broker

### **Orchestration**
- **Kubernetes** (1.28+)
- **Helm** (3.0+)
- **Azure Kubernetes Service (AKS)**
- **Azure Application Gateway Ingress Controller (AGIC)**

---

## ✅ Prerequisites

### **1. Azure CLI**
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Set subscription (if you have multiple)
az account set --subscription "your-subscription-id"
```

### **2. kubectl**
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify
kubectl version --client
```

### **3. Helm**
```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version
```

### **4. Azure Resources**
- Active Azure subscription
- Resource group created
- Sufficient quota for AKS cluster (minimum: 4 vCPUs)

---

## 🚀 Quick Start

**Deploy the entire platform in 5 minutes:**

```bash
# 1. Clone the repository
git clone https://github.com/chellojuramu/aks-ecommerce-platform.git
cd aks-ecommerce-platform/AKS

# 2. Create AKS cluster (takes 5-10 minutes)
az aks create \
  --resource-group ecommerce-demo \
  --name roboshop \
  --location westus2 \
  --node-count 2 \
  --node-vm-size Standard_D4ds_v5 \
  --kubernetes-version 1.28 \
  --enable-managed-identity \
  --network-plugin azure \
  --generate-ssh-keys

# 3. Get cluster credentials
az aks get-credentials --resource-group ecommerce-demo --name roboshop

# 4. Enable Application Gateway Ingress Controller (AGIC)
az aks enable-addons \
  --resource-group ecommerce-demo \
  --name roboshop \
  --addons ingress-appgw \
  --appgw-name roboshop-appgw \
  --appgw-subnet-cidr 10.225.0.0/16

# 5. Deploy application with Helm
cd helm
helm install roboshop --namespace roboshop --create-namespace .

# 6. Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all -n roboshop --timeout=300s

# 7. Get application URL
kubectl get ingress -n roboshop
# Access: http://<ADDRESS>
```

**🎉 Your application is now live!**

---

## 📚 Detailed Installation

### **Step 1: Create AKS Cluster**

**Using the provided script:**

```bash
cd aks-ecommerce-platform/AKS

# Make script executable
chmod +x create-aks.sh

# Run cluster creation
./create-aks.sh
```

**Or manually with Azure CLI:**

```bash
# Create resource group
az group create \
  --name ecommerce-demo \
  --location westus2

# Create AKS cluster with spot instances (cost-optimized)
az aks create \
  --resource-group ecommerce-demo \
  --name roboshop \
  --location westus2 \
  --node-count 2 \
  --node-vm-size Standard_D4ds_v5 \
  --kubernetes-version 1.28 \
  --enable-managed-identity \
  --network-plugin azure \
  --network-policy azure \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5 \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \
  --generate-ssh-keys \
  --tags environment=dev project=roboshop

# Get cluster credentials
az aks get-credentials \
  --resource-group ecommerce-demo \
  --name roboshop \
  --overwrite-existing

# Verify connection
kubectl cluster-info
kubectl get nodes
```

---

### **Step 2: Enable AGIC (Azure Application Gateway Ingress)**

```bash
# Enable Application Gateway Ingress Controller addon
az aks enable-addons \
  --resource-group ecommerce-demo \
  --name roboshop \
  --addons ingress-appgw \
  --appgw-name roboshop-appgw \
  --appgw-subnet-cidr 10.225.0.0/16

# Verify AGIC installation
kubectl get pods -n kube-system | grep ingress-azure
# Expected: ingress-appgw-deployment-xxxxx   1/1   Running
```

---

### **Step 3: Deploy Application with Helm**

```bash
cd aks-ecommerce-platform/AKS/helm

# Lint the chart (check for errors)
helm lint .

# Dry-run to preview what will be deployed
helm install roboshop --namespace roboshop --create-namespace . --dry-run --debug

# Deploy to AKS
helm install roboshop --namespace roboshop --create-namespace .

# Verify deployment
helm list -n roboshop
kubectl get all -n roboshop
```

---

### **Step 4: Verify All Pods are Running**

```bash
# Check pod status
kubectl get pods -n roboshop

# Expected output (all 1/1 Running):
# NAME                         READY   STATUS    RESTARTS   AGE
# cart-xxx                     1/1     Running   0          2m
# catalogue-xxx                1/1     Running   0          2m
# frontend-xxx                 1/1     Running   0          1m
# mongodb-xxx                  1/1     Running   0          3m
# mysql-xxx                    1/1     Running   0          3m
# payment-xxx                  1/1     Running   0          2m
# rabbitmq-xxx                 1/1     Running   0          3m
# redis-0                      1/1     Running   0          3m
# shipping-xxx                 1/1     Running   0          1m
# user-xxx                     1/1     Running   0          2m

# Watch pods until all are running
kubectl get pods -n roboshop -w
# Press Ctrl+C when all show Running
```

**⏱ Deployment time:** 2-3 minutes  
**Note:** `shipping` (Java) takes longest to start (~60s)

---

## ⚙️ Configuration

### **Helm Values Overview**

The `values.yaml` file controls all deployment parameters:

```yaml
# Global settings
namespace: roboshop

# Ingress (Azure Application Gateway)
ingress:
  enabled: true              # Use Ingress (recommended)
  name: roboshop

# Individual service configuration
frontend:
  enabled: true
  replicaCount: 1
  service:
    type: ClusterIP          # Internal (Ingress handles external access)
    port: 80
    targetPort: 8080

# Resource limits (production-ready)
mongodb:
  resources:
    limits:
      cpu: "200m"
      memory: "512Mi"        # Prevents OOMKilled errors
    requests:
      cpu: "100m"
      memory: "256Mi"
```

### **Common Customizations**

**1. Change number of replicas (for HA):**

```bash
helm upgrade roboshop --namespace roboshop . \
  --set catalogue.replicaCount=3 \
  --set cart.replicaCount=3 \
  --set frontend.replicaCount=3
```

**2. Enable persistence for databases:**

```yaml
# In values.yaml
mongodb:
  persistence:
    enabled: true            # Changed from false
    size: 50Gi
    storageClass: managed-csi

redis:
  persistence:
    enabled: true
    size: 10Gi
```

**3. Use existing secrets (for production):**

```bash
# Create secret manually
kubectl create secret generic mysql-prod-secret \
  -n roboshop \
  --from-literal=root-password='YourStrongPassword123!'

# Update values.yaml
mysql:
  auth:
    existingSecret: "mysql-prod-secret"
```

---

## 🌐 Accessing the Application

### **Via Ingress (Default)**

```bash
# Get Ingress IP address
kubectl get ingress -n roboshop

# Output:
# NAME       CLASS                       ADDRESS         PORTS   AGE
# roboshop   azure-application-gateway   4.154.253.31    80      10m
#                                        ↑ Use this IP

# Access in browser
echo "Application URL: http://$(kubectl get ingress roboshop -n roboshop -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

# Test with curl
curl http://4.154.253.31
```

### **Via LoadBalancer (Alternative)**

If you prefer direct LoadBalancer access instead of Ingress:

```bash
# Switch to LoadBalancer
helm upgrade roboshop --namespace roboshop . \
  --set ingress.enabled=false \
  --set frontend.service.type=LoadBalancer

# Get LoadBalancer IP
kubectl get svc frontend -n roboshop
# Access: http://<EXTERNAL-IP>
```

---

## 🧪 Testing API Endpoints

```bash
# Save Ingress IP
INGRESS_IP=$(kubectl get ingress roboshop -n roboshop -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test catalogue API (get products)
curl http://$INGRESS_IP/api/catalogue/products | jq

# Test user health
curl http://$INGRESS_IP/api/user/health

# Test cart health
curl http://$INGRESS_IP/api/cart/health

# Test payment health
curl http://$INGRESS_IP/api/payment/health

# Test shipping health
curl http://$INGRESS_IP/api/shipping/health

# Test nginx status
curl http://$INGRESS_IP/health
```

**Expected response:** JSON data or `{"status":"OK"}`

---

## 🐛 Troubleshooting

### **Problem: Pod stuck in `Pending`**

```bash
# Check pod events
kubectl describe pod <pod-name> -n roboshop

# Common causes:
# 1. Insufficient cluster resources
kubectl top nodes

# 2. PVC binding issues
kubectl get pvc -n roboshop

# 3. Node affinity/taints
kubectl get nodes --show-labels
```

**Solution:** Scale up cluster or adjust resource requests

---

### **Problem: Pod in `CrashLoopBackOff`**

```bash
# Check pod logs
kubectl logs <pod-name> -n roboshop

# Check previous logs (if container restarted)
kubectl logs <pod-name> -n roboshop --previous

# Common issues:
# - MongoDB: OOMKilled → Increase memory limit (see Configuration)
# - Frontend: Permission denied → Port 8080 fix already applied
# - Java: Slow startup → Use startup probe (already configured)
```

---

### **Problem: `ImagePullBackOff`**

```bash
# Check image pull errors
kubectl describe pod <pod-name> -n roboshop | grep -A 5 "Events"

# Verify image exists
docker pull chelloju/roboshop-cart:2.0

# If image is correct, check image pull secrets
kubectl get secrets -n roboshop
```

---

### **Problem: Ingress has no IP address**

```bash
# Check AGIC controller status
kubectl get pods -n kube-system | grep ingress-azure

# If no pods, AGIC is not installed
az aks enable-addons \
  --resource-group ecommerce-demo \
  --name roboshop \
  --addons ingress-appgw \
  --appgw-name roboshop-appgw \
  --appgw-subnet-cidr 10.225.0.0/16

# Check Application Gateway backend health
az network application-gateway show-backend-health \
  --resource-group ecommerce-demo \
  --name roboshop-appgw
```

---

### **Problem: 502 Bad Gateway via Ingress**

```bash
# 1. Verify frontend service is ClusterIP (not LoadBalancer)
kubectl get svc frontend -n roboshop
# TYPE should be ClusterIP

# 2. Check frontend pods are running
kubectl get pods -n roboshop -l component=frontend

# 3. Test frontend internally
kubectl exec -n roboshop -it \
  $(kubectl get pod -n roboshop -l component=frontend -o jsonpath='{.items[0].metadata.name}') \
  -- curl localhost:8080/health

# 4. Check AGIC logs
kubectl logs -n kube-system -l app=ingress-appgw --tail=100
```

---

## 📊 Monitoring & Observability

### **Check Resource Usage**

```bash
# Pod resource consumption
kubectl top pods -n roboshop

# Node resource consumption
kubectl top nodes

# Persistent Volume usage
kubectl get pv
```

### **View Logs**

```bash
# Stream logs from a specific service
kubectl logs -f -l component=catalogue -n roboshop

# View logs from all pods with a label
kubectl logs -l tier=backend -n roboshop --tail=50

# View logs from previous container restart
kubectl logs <pod-name> -n roboshop --previous
```

### **Port-Forward for Local Testing**

```bash
# Access RabbitMQ Management UI
kubectl port-forward -n roboshop svc/rabbitmq 15672:15672
# Open: http://localhost:15672
# Default credentials: guest/guest (configured in values.yaml)

# Access MongoDB directly
kubectl port-forward -n roboshop svc/mongodb 27017:27017
# Connect: mongodb://localhost:27017

# Access Redis
kubectl port-forward -n roboshop svc/redis 6379:6379
# Connect: redis-cli -h localhost -p 6379
```

---

## 🏭 Production Best Practices

### **1. Enable Resource Limits for All Services**

Already configured in `values.yaml`:

```yaml
# Each service has defined limits
cart:
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "200m"
      memory: "256Mi"
```

### **2. Enable Persistent Storage**

```yaml
# For production, enable persistence
mongodb:
  persistence:
    enabled: true          # Change to true
    size: 100Gi           # Increase size
    storageClass: managed-csi

mysql:
  persistence:
    enabled: true
    size: 100Gi
```

### **3. Use Secrets for Sensitive Data**

```bash
# Create secrets outside Helm
kubectl create secret generic mysql-prod-secret \
  -n roboshop \
  --from-literal=root-password='StrongPassword123!'

kubectl create secret generic rabbitmq-prod-secret \
  -n roboshop \
  --from-literal=rabbitmq-user='admin' \
  --from-literal=rabbitmq-pass='AdminPass123!'

# Reference in values.yaml
mysql:
  auth:
    existingSecret: "mysql-prod-secret"

rabbitmq:
  auth:
    existingSecret: "rabbitmq-prod-secret"
```

### **4. Enable High Availability**

```bash
# Deploy with multiple replicas
helm upgrade roboshop --namespace roboshop . \
  --set catalogue.replicaCount=3 \
  --set cart.replicaCount=3 \
  --set user.replicaCount=3 \
  --set payment.replicaCount=2 \
  --set shipping.replicaCount=2 \
  --set frontend.replicaCount=3
```

### **5. Configure Auto-Scaling**

```yaml
# Add to values.yaml for each service
catalogue:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

### **6. Enable Network Policies**

```bash
# Create NetworkPolicy to restrict pod-to-pod communication
kubectl apply -f network-policies/
```

---

## 🧹 Cleanup

### **Delete Application (Keep Cluster)**

```bash
# Uninstall Helm release
helm uninstall roboshop -n roboshop

# Delete namespace
kubectl delete namespace roboshop

# Verify deletion
kubectl get all -n roboshop
```

### **Delete Entire AKS Cluster**

```bash
# Using provided script
cd aks-ecommerce-platform/AKS
./delete-aks.sh

# Or manually
az aks delete \
  --resource-group ecommerce-demo \
  --name roboshop \
  --yes \
  --no-wait

# Delete resource group (removes everything)
az group delete --name ecommerce-demo --yes --no-wait
```

**⚠️ Warning:** This will delete all resources and data permanently!

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](../LICENSE) file for details.

---

## 👨‍💻 Author

**Ramu Chelloju**  
DevOps Engineer | Azure & Kubernetes Specialist

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=for-the-badge&logo=linkedin)](https://www.linkedin.com/in/ramuchelloju/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=for-the-badge&logo=github)](https://github.com/chellojuramu)

💼 **Let's Connect:**  
- [LinkedIn](https://www.linkedin.com/in/ramuchelloju/) - Follow for DevOps insights & tutorials  
- [GitHub](https://github.com/chellojuramu) - More production-ready projects  
- [Portfolio](https://chellojuramu.github.io) - Complete project showcase  


## 📚 Additional Resources

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Helm Official Documentation](https://helm.sh/docs/)
- [Azure AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [Azure Application Gateway Ingress Controller](https://azure.github.io/application-gateway-kubernetes-ingress/)

---

## 🌟 Star History

If you found this project helpful, please consider giving it a ⭐ on GitHub!

---

<div align="center">

**Built with ❤️ by [Ramu Chelloju](https://www.linkedin.com/in/ramuchelloju/)**

**Follow me on LinkedIn for more DevOps content!**

</div>
