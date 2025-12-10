# Wisecow Application – Containerization, Kubernetes Deployment & CI/CD Pipeline

This repository contains the fully containerized Wisecow Application, deployed on a Kubernetes (Minikube) cluster with an automated CI/CD pipeline using GitHub Actions

---

## 📌 Problem Statement 1 – Summary

**Objective**

Containerize the Wisecow application and deploy it on Kubernetes, secured with TLS and automated using a CI/CD pipeline.

**Final Deliverables**

- Dockerfile  
- Kubernetes manifests  
- TLS certificates & Ingress  
- GitHub Actions CI/CD pipeline  
- Working Kubernetes deployment  
- Public GitHub repository

---

## 🚀 1. Application Containerization

A Dockerfile is provided to package the Wisecow application into a portable container image.

**Build Command (automated by CI/CD):**
```bash
docker build -t <DOCKERHUB_USERNAME>/wisecow:latest .
```

---

## ☸️ 2. Kubernetes Deployment

The Kubernetes manifests include:

- **Deployment** (`k8s/wisecow-deployment.yaml`)
  - 2 replicas
  - Liveness & Readiness probes (`/health`)
  - Pulls image from Docker Hub

- **Service** (`k8s/wisecow-service.yaml`)
  - Exposes port `4499`

- **Ingress + TLS**
  - Minikube ingress
  - Self-signed TLS certificate (example subject `wisecow.local`)
  - Virtual host → `wisecow.local`

Apply manifests:
```bash
kubectl apply -f k8s/
kubectl -n wisecow get pods
```

---

## 🔐 3. TLS Implementation

Example of generating a self-signed certificate:
```bash
mkdir -p wisecow-certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048   -keyout wisecow.local.key -out wisecow.local.crt   -subj "/CN=wisecow.local/O=wisecow"
```

Create TLS secret:
```bash
kubectl -n wisecow create secret tls wisecow-tls   --cert=wisecow.local.crt --key=wisecow.local.key
```

---

## 🤖 4. CI/CD Pipeline – GitHub Actions

Self-hosted runner enabled full deployment automation.

**CI Pipeline**
- Triggers on commits to `main`
- Builds Docker image
- Pushes to Docker Hub (`<DOCKERHUB_USERNAME>/wisecow`)

**CD Pipeline**
- Automatically deploys the updated application to Minikube (using a runner or kubeconfig secret)
- Performs rolling updates

Workflow files:
- `.github/workflows/build-and-push.yml`
- `.github/workflows/deploy-to-minikube.yml`

---

## 🧪 5.Automation Scripts

Two automation scripts were developed:

### Script 1️⃣ – System Health Monitor (`scripts/system_health.sh`)

Monitors:
- CPU usage
- Memory usage
- Disk usage

Logs alerts to:
```
~/sys_health.log
```

Run:
```bash
~/wisecow/scripts/system_health.sh
```

### Script 2️⃣ – Application Health Checker (`scripts/app_health.sh`)

Checks application uptime using HTTP status code validation.

Run:
```bash
~/wisecow/scripts/app_health.sh http://localhost:4499 200
```

Log file:
```
~/app_health.log
```

---

## 📸 Screenshots

All screenshots (CI/CD runs, Minikube deployment, TLS, scripts, etc.) are available here:

👉 https://drive.google.com/drive/folders/1NC_X2LwvmYLdzDgcpNJi_qIc42CM_x4Z?usp=sharing

--

