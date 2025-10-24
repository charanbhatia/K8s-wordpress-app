# Production-Grade WordPress on Kubernetes

Complete production-ready WordPress deployment on Kubernetes with Nginx (OpenResty + Lua), MySQL, and comprehensive monitoring using Prometheus/Grafana.

## Architecture

```
┌─────────────┐
│  LoadBalancer│
└──────┬──────┘
       │
┌──────▼──────────┐
│  Nginx (OpenResty)│ (Port 80)
│  with Lua       │
└──────┬──────────┘
       │
┌──────▼──────────┐
│  WordPress      │ (Port 9000)
│  PHP-FPM        │
└──────┬──────────┘
       │
┌──────▼──────────┐
│  MySQL          │ (Port 3306)
└─────────────────┘
```

## Prerequisites

- Kubernetes cluster (v1.24+)
- kubectl configured
- Helm 3.x installed
- Docker for building images
- 20GB+ available storage

## Quick Start

### 1. Build Docker Images

```bash
cd docker/mysql
docker build -t mysql-custom:latest .

cd ../wordpress
docker build -t wordpress-custom:latest .

cd ../nginx
docker build -t nginx-openresty:latest .
```

### 2. Deploy WordPress Application

```bash
cd helm/wordpress
helm install my-release .
```

### 3. Deploy Monitoring Stack

```bash
cd ../monitoring
helm dependency update
helm install monitoring .
```

### 4. Access Services

```bash
kubectl get services
```

Access WordPress: `http://<nginx-service-external-ip>`
Access Grafana: `http://<grafana-service-external-ip>`

## Detailed Deployment

### Step 1: Prepare Docker Images

Build all three custom Docker images:

**MySQL:**
```bash
cd docker/mysql
docker build -t mysql-custom:latest .
docker tag mysql-custom:latest <your-registry>/mysql-custom:latest
docker push <your-registry>/mysql-custom:latest
```

**WordPress:**
```bash
cd docker/wordpress
docker build -t wordpress-custom:latest .
docker tag wordpress-custom:latest <your-registry>/wordpress-custom:latest
docker push <your-registry>/wordpress-custom:latest
```

**Nginx with OpenResty:**
```bash
cd docker/nginx
docker build -t nginx-openresty:latest .
docker tag nginx-openresty:latest <your-registry>/nginx-openresty:latest
docker push <your-registry>/nginx-openresty:latest
```

### Step 2: Configure Values

Edit `helm/wordpress/values.yaml`:

```yaml
image:
  mysql:
    repository: <your-registry>/mysql-custom
    tag: latest
  wordpress:
    repository: <your-registry>/wordpress-custom
    tag: latest
  nginx:
    repository: <your-registry>/nginx-openresty
    tag: latest

mysql:
  rootPassword: <secure-password>
  password: <secure-password>

persistence:
  mysql:
    size: 20Gi
  wordpress:
    size: 20Gi
```

### Step 3: Deploy WordPress

```bash
cd helm/wordpress
helm install my-release . --namespace default
```

Verify deployment:
```bash
kubectl get pods
kubectl get pvc
kubectl get services
```

### Step 4: Deploy Monitoring

```bash
cd helm/monitoring
helm dependency update
helm install monitoring . --namespace default
```

Wait for pods to be ready:
```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana --timeout=300s
```

### Step 5: Access Grafana

Get Grafana service:
```bash
kubectl get service monitoring-grafana
```

Default credentials:
- Username: `admin`
- Password: `admin`

## Configuration

### WordPress Configuration

Environment variables can be set in `values.yaml`:

```yaml
wordpress:
  dbHost: mysql
  dbName: wordpress
  dbUser: wpuser
  dbPassword: wppass
```

### Nginx Configuration

Nginx is configured with:
- Lua scripting support
- FastCGI proxy to WordPress
- Access and error logging
- Health check endpoint: `/health`
- Status endpoint: `/nginx_status`

### MySQL Configuration

Custom MySQL configuration in `docker/mysql/custom.cnf`:
- InnoDB optimization
- Connection pooling
- Slow query logging

### Scaling

Scale WordPress and Nginx horizontally:

```bash
kubectl scale deployment my-release-wordpress-wordpress --replicas=5
kubectl scale deployment my-release-wordpress-nginx --replicas=5
```

Or enable autoscaling in `values.yaml`:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

## Monitoring

### Metrics Collected

- **Pod CPU utilization**: Per-container CPU usage
- **Pod memory utilization**: Per-container memory usage
- **Nginx total requests**: HTTP request count
- **Nginx 5xx errors**: Server error count
- **Request latency**: Response time percentiles
- **MySQL connections**: Active database connections
- **MySQL queries**: Query execution metrics

See [METRICS.md](METRICS.md) for complete metrics documentation.

### Grafana Dashboards

Pre-configured dashboards include:
- WordPress Overview
- Nginx Performance
- MySQL Performance
- Kubernetes Cluster Metrics

### Alerts

Configured alerts:
- High CPU usage (>80% for 5min)
- High memory usage (>80% for 5min)
- High 5xx error rate (>5% for 2min)
- Pod down (>1min)
- High request latency (p95 >1s for 5min)

## Testing

### Test WordPress Installation

```bash
WORDPRESS_IP=$(kubectl get service my-release-wordpress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$WORDPRESS_IP
```

### Test Health Endpoints

```bash
curl http://$WORDPRESS_IP/health
curl http://$WORDPRESS_IP/nginx_status
```

### Load Testing

```bash
kubectl run -it --rm load-test --image=busybox --restart=Never -- sh -c "while true; do wget -q -O- http://my-release-wordpress-nginx; done"
```

### View Logs

```bash
kubectl logs -l component=nginx -f
kubectl logs -l component=wordpress -f
kubectl logs -l component=mysql -f
```

## Troubleshooting

### Pods Not Starting

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### PVC Issues

```bash
kubectl get pvc
kubectl describe pvc <pvc-name>
```

### Database Connection Issues

```bash
kubectl exec -it <wordpress-pod> -- env | grep DB
kubectl exec -it <mysql-pod> -- mysql -u root -p
```

### Nginx Configuration

```bash
kubectl exec -it <nginx-pod> -- nginx -t
kubectl exec -it <nginx-pod> -- cat /opt/openresty/nginx/conf/nginx.conf
```

## Cleanup

### Delete WordPress Release

```bash
helm delete my-release
```

### Delete Monitoring Stack

```bash
helm delete monitoring
```

### Delete PVCs

```bash
kubectl delete pvc --all
```

### Delete PVs

```bash
kubectl delete pv --all
```

## Production Considerations

1. **Security**
   - Use Kubernetes Secrets for sensitive data
   - Enable TLS/SSL certificates
   - Implement network policies
   - Regular security updates

2. **Backup**
   - Implement automated MySQL backups
   - Backup WordPress uploads directory
   - Test restore procedures

3. **High Availability**
   - Multi-zone deployment
   - Database replication
   - Load balancer health checks

4. **Performance**
   - CDN for static assets
   - Redis/Memcached for caching
   - Database query optimization
   - Image optimization

5. **Monitoring**
   - Set up alerting channels
   - Regular dashboard reviews
   - Log aggregation (ELK/Loki)
   - APM integration

## OpenResty Configuration

Nginx is compiled with OpenResty including:
- PCRE JIT compilation
- IPv6 support
- HTTP iconv module
- PostgreSQL module
- Lua scripting support

Configure options used:
```bash
./configure --prefix=/opt/openresty \
    --with-pcre-jit \
    --with-ipv6 \
    --without-http_redis2_module \
    --with-http_iconv_module \
    --with-http_postgres_module \
    -j8
```

## Support

For issues and questions:
- Check logs: `kubectl logs <pod-name>`
- Review metrics in Grafana
- Check [METRICS.md](METRICS.md) for monitoring details

## License

MIT License
