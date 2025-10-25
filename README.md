# Production-Grade WordPress on Kubernetes

Complete production-ready WordPress deployment on Kubernetes with Nginx (OpenResty + Lua), MySQL 8.0, and comprehensive monitoring using Prometheus/Grafana.

## Architecture

```
┌─────────────────┐
│  LoadBalancer   │
└────────┬────────┘
         │
┌────────▼──────────┐
│ Nginx (OpenResty) │ (2 replicas)
│   with Lua        │ Port 80
└────────┬──────────┘
         │
┌────────▼──────────┐
│   WordPress       │ (2 replicas)
│   PHP 8.1-FPM     │ Port 9000
└────────┬──────────┘
         │
┌────────▼──────────┐
│   MySQL 8.0       │ (1 replica)
│                   │ Port 3306
└───────────────────┘

Monitoring:
┌─────────────┐    ┌──────────┐
│ Prometheus  │───▶│ Grafana  │
└─────────────┘    └──────────┘
```

## Features

- ✅ Production-grade WordPress with PHP 8.1-FPM
- ✅ MySQL 8.0 with optimized InnoDB configuration
- ✅ Nginx with OpenResty (Lua scripting support)
- ✅ Persistent storage for database and WordPress files
- ✅ Horizontal scaling for WordPress and Nginx
- ✅ Prometheus metrics collection
- ✅ Grafana dashboards for monitoring
- ✅ Health check endpoints
- ✅ Resource limits and requests

## Prerequisites

- Kubernetes cluster (v1.24+)
- kubectl configured
- Docker (for building custom images)
- 20GB+ available storage

## Quick Start

### 1. Deploy WordPress Application

```bash
# Create WordPress namespace
kubectl create namespace wordpress

# Deploy storage
kubectl apply -f k8s/mysql-pvc.yaml
kubectl apply -f k8s/wordpress-pvc.yaml

# Deploy MySQL
kubectl apply -f k8s/mysql-deployment.yaml

# Deploy WordPress
kubectl apply -f k8s/wordpress-deployment.yaml

# Deploy Nginx
kubectl apply -f k8s/nginx-deployment.yaml

# Verify deployment
kubectl get pods -n wordpress
```

Expected output:
```
NAME                                   READY   STATUS    RESTARTS   AGE
wordpress-mysql-xxxxxxxxx-xxxxx        1/1     Running   0          2m
wordpress-nginx-xxxxxxxxx-xxxxx        1/1     Running   0          1m
wordpress-nginx-xxxxxxxxx-xxxxx        1/1     Running   0          1m
wordpress-wordpress-xxxxxxxxx-xxxxx    1/1     Running   0          1m
wordpress-wordpress-xxxxxxxxx-xxxxx    1/1     Running   0          1m
```

### 2. Deploy Monitoring Stack

```bash
# Deploy Prometheus and Grafana
kubectl apply -f k8s/monitoring/namespace.yaml
kubectl apply -f k8s/monitoring/prometheus-rbac.yaml
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/prometheus-deployment.yaml
kubectl apply -f k8s/monitoring/grafana-config.yaml
kubectl apply -f k8s/monitoring/grafana-deployment.yaml

# Verify monitoring pods
kubectl get pods -n monitoring
```

### 3. Access Applications

**WordPress:**
```bash
kubectl port-forward -n wordpress svc/wordpress-nginx 8080:80
```
Open http://localhost:8080 in your browser

**Grafana Dashboard:**
```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
```
Open http://localhost:3000 (Login: admin / admin123)

**Prometheus:**
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```
Open http://localhost:9090

## Docker Images

All images are available on Docker Hub:
- `charanbhatia/mysql-custom:latest` - MySQL 8.0 with production config
- `charanbhatia/wordpress-custom:latest` - WordPress with PHP 8.1-FPM
- `charanbhatia/nginx-openresty:latest` - Nginx with OpenResty and Lua

### Build Custom Images (Optional)

```bash
# MySQL
docker build -t charanbhatia/mysql-custom:latest -f docker/mysql/Dockerfile docker/mysql
docker push charanbhatia/mysql-custom:latest

# WordPress
docker build -t charanbhatia/wordpress-custom:latest -f docker/wordpress/Dockerfile docker/wordpress
docker push charanbhatia/wordpress-custom:latest

# Nginx with OpenResty
docker build -t charanbhatia/nginx-openresty:latest -f docker/nginx/Dockerfile docker/nginx
docker push charanbhatia/nginx-openresty:latest
```

## Configuration

### WordPress Environment Variables

Configured in `k8s/wordpress-deployment.yaml`:
```yaml
env:
  - name: WORDPRESS_DB_HOST
    value: wordpress-mysql:3306
  - name: WORDPRESS_DB_NAME
    value: wordpress
  - name: WORDPRESS_DB_USER
    value: wpuser
  - name: WORDPRESS_DB_PASSWORD
    value: wppass
```

### MySQL Configuration

Custom configuration in `docker/mysql/custom.cnf`:
- Max connections: 200
- InnoDB buffer pool: 256MB
- InnoDB log file size: 64MB
- Character set: utf8mb4
- Optimized for WordPress workloads

### Nginx Configuration

Features:
- OpenResty with Lua scripting
- FastCGI proxy to WordPress PHP-FPM
- Custom logging format for metrics
- Health endpoint: `/health`
- Static asset caching
- Prometheus annotations for scraping

## Scaling

### Horizontal Scaling

Scale WordPress application:
```bash
kubectl scale deployment wordpress-wordpress -n wordpress --replicas=5
```

Scale Nginx:
```bash
kubectl scale deployment wordpress-nginx -n wordpress --replicas=5
```

### Resource Configuration

Current resource limits per pod:
- **MySQL**: 512Mi-1Gi memory, 250m-500m CPU
- **WordPress**: 256Mi-512Mi memory, 200m-400m CPU
- **Nginx**: 128Mi-256Mi memory, 100m-200m CPU

## Monitoring

### Metrics Collected

- **Pod CPU/Memory**: Container resource usage
- **Nginx Requests**: Total HTTP requests
- **Nginx Errors**: 5xx error count
- **Request Latency**: Response time metrics
- **MySQL Connections**: Database connections
- **Pod Status**: Health and availability

### Grafana Dashboards

Pre-configured dashboard includes:
1. Request Rate (per instance)
2. 5xx Error Rate
3. CPU Usage (per pod)
4. Memory Usage (per pod)

### Prometheus Targets

Configured to scrape:
- Kubernetes pods with Prometheus annotations
- WordPress Nginx pods
- Prometheus self-monitoring

## Persistence

### MySQL Data

- **PVC**: wordpress-mysql-pvc
- **Size**: 10Gi
- **Mount**: /var/lib/mysql
- **Access**: ReadWriteOnce

> **Note**: The PDF requirements specify ReadWriteMany for deployment scaling. However, Docker Desktop Kubernetes doesn't support ReadWriteMany with hostPath volumes. For production deployments on cloud providers (AWS, GCP, Azure), use:
> - AWS EFS (elastic file system)
> - GCP Filestore
> - Azure Files
> - NFS-based storage solutions
> 
> To enable ReadWriteMany, update the PVC `accessModes` from `ReadWriteOnce` to `ReadWriteMany` and use an appropriate StorageClass.

### WordPress Files

- **PVC**: wordpress-wordpress-pvc
- **Size**: 10Gi
- **Mount**: /var/www/html
- **Access**: ReadWriteOnce
- **Init Container**: Copies WordPress files on first boot

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n wordpress
kubectl describe pod <pod-name> -n wordpress
kubectl logs <pod-name> -n wordpress
```

### Check Services

```bash
kubectl get svc -n wordpress
kubectl get svc -n monitoring
```

### Test Database Connection

```bash
kubectl exec -it <mysql-pod> -n wordpress -- mysql -u wpuser -pwppass wordpress -e "SHOW TABLES;"
```

### Verify WordPress Files

```bash
kubectl exec -it <wordpress-pod> -n wordpress -- ls -la /var/www/html
```

### Check Nginx Configuration

```bash
kubectl exec -it <nginx-pod> -n wordpress -- nginx -t
```

### View Logs

```bash
# All WordPress pods
kubectl logs -l app=wordpress -n wordpress --all-containers=true

# Specific component
kubectl logs -l component=nginx -n wordpress -f
kubectl logs -l component=wordpress -n wordpress -f
kubectl logs -l component=mysql -n wordpress -f
```

## Cleanup

### Delete WordPress

```bash
kubectl delete namespace wordpress
```

### Delete Monitoring

```bash
kubectl delete namespace monitoring
```

### Delete Persistent Volumes

```bash
kubectl delete pv wordpress-mysql-pv wordpress-wordpress-pv
```

## Production Considerations

### Security
- ✅ Use Kubernetes Secrets for passwords
- ✅ Enable TLS/SSL with cert-manager
- ✅ Implement network policies
- ✅ Regular security updates
- ✅ Non-root container users

### High Availability
- ✅ Multi-replica deployments
- ✅ Pod disruption budgets
- ✅ Readiness and liveness probes
- ✅ Rolling updates strategy
- ⚠️ Database replication (not implemented)

### Backup Strategy
- ⚠️ Automated MySQL backups (not implemented)
- ⚠️ WordPress uploads backup (not implemented)
- ✅ Persistent volume snapshots available

### Performance Optimization
- ✅ OpCache enabled for PHP
- ✅ Static asset caching in Nginx
- ✅ Resource limits configured
- ⚠️ Redis/Memcached caching (not implemented)
- ⚠️ CDN integration (not implemented)

## Technical Details

### OpenResty Compilation

Nginx compiled with OpenResty including:
```bash
./configure --prefix=/opt/openresty \
    --with-pcre-jit \
    --with-ipv6 \
    --without-http_redis2_module \
    --with-http_iconv_module \
    --with-http_postgres_module \
    --with-http_stub_status_module \
    -j8
```

### PHP Extensions

Installed extensions:
- gd (image processing)
- mysqli, pdo_mysql (database)
- zip (file compression)
- opcache (performance)
- exif (image metadata)
- bcmath (calculations)
- redis (caching - driver installed)

### WordPress Initialization

WordPress deployment uses init container to:
1. Check if WordPress files exist in PVC
2. Copy files from container to PVC on first boot
3. Preserve data across pod restarts

## Project Structure

```
.
├── docker/
│   ├── mysql/              # MySQL 8.0 Dockerfile and config
│   ├── wordpress/          # WordPress PHP-FPM Dockerfile
│   └── nginx/              # Nginx OpenResty Dockerfile
├── k8s/
│   ├── mysql-pvc.yaml
│   ├── mysql-deployment.yaml
│   ├── wordpress-pvc.yaml
│   ├── wordpress-deployment.yaml
│   ├── nginx-deployment.yaml
│   └── monitoring/         # Prometheus & Grafana manifests
├── helm/                   # Helm charts (reference)
│   ├── wordpress/
│   └── monitoring/
└── README.md
```

## License

MIT License

## Author

Created for production WordPress deployment on Kubernetes with monitoring and observability.
