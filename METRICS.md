# WordPress Application Metrics Documentation

This document outlines all required metrics for monitoring the WordPress application stack running on Kubernetes.

## Overview

The monitoring stack consists of:
- **Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboarding
- **WordPress Application**: PHP-FPM based WordPress
- **MySQL Database**: Data persistence layer
- **Nginx (OpenResty)**: Reverse proxy with Lua support

## Container Metrics

### 1. Pod CPU Utilization

**Metric Name**: `container_cpu_usage_seconds_total`

**Description**: Cumulative CPU time consumed by containers in seconds

**Query Examples**:
```promql
# CPU usage rate per pod (last 5 minutes)
rate(container_cpu_usage_seconds_total{pod=~"wordpress-.*"}[5m])

# CPU usage percentage
rate(container_cpu_usage_seconds_total{pod=~"wordpress-.*"}[5m]) * 100

# Top CPU consuming pods
topk(5, rate(container_cpu_usage_seconds_total{namespace="wordpress"}[5m]))
```

**Alert Threshold**: 
- Warning: > 70% CPU usage
- Critical: > 90% CPU usage

**Visualization**: Line graph showing CPU usage over time per pod

---

### 2. Pod Memory Utilization

**Metric Name**: `container_memory_usage_bytes`

**Description**: Current memory usage in bytes

**Query Examples**:
```promql
# Memory usage in MB
container_memory_usage_bytes{pod=~"wordpress-.*"} / 1024 / 1024

# Memory usage percentage
(container_memory_usage_bytes{pod=~"wordpress-.*"} / 
 container_spec_memory_limit_bytes{pod=~"wordpress-.*"}) * 100
```

**Alert Threshold**:
- Warning: > 80% memory usage
- Critical: > 95% memory usage

**Visualization**: Line graph with memory limits overlay

---

## Nginx Metrics

### 3. Total Request Count

**Metric Name**: `nginx_http_requests_total`

**Description**: Total number of HTTP requests processed by Nginx

**Query Examples**:
```promql
# Request rate (requests per second)
rate(nginx_http_requests_total[5m])

# Total requests in last hour
increase(nginx_http_requests_total[1h])

# Requests by status code
sum by (status) (rate(nginx_http_requests_total[5m]))
```

**Alert Threshold**:
- Warning: Request rate drops below 1 req/s (indicates downtime)
- Critical: No requests for 5 minutes

**Visualization**: 
- Counter showing total requests
- Line graph showing request rate over time

---

### 4. Total 5xx Errors

**Metric Name**: `nginx_http_requests_total{status=~"5.."}`

**Description**: HTTP 5xx server errors returned by Nginx

**Query Examples**:
```promql
# 5xx error rate
rate(nginx_http_requests_total{status=~"5.."}[5m])

# 5xx error percentage
(rate(nginx_http_requests_total{status=~"5.."}[5m]) / 
 rate(nginx_http_requests_total[5m])) * 100

# Total 5xx errors in last hour
sum(increase(nginx_http_requests_total{status=~"5.."}[1h]))
```

**Alert Threshold**:
- Warning: > 1% error rate
- Critical: > 5% error rate

**Visualization**:
- Line graph showing error rate
- Single stat showing current error percentage

---

### 5. Nginx Active Connections

**Metric Name**: `nginx_connections_active`

**Description**: Current number of active client connections

**Query Examples**:
```promql
# Current active connections
nginx_connections_active

# Average active connections (5min)
avg_over_time(nginx_connections_active[5m])
```

**Alert Threshold**:
- Warning: > 80% of max connections
- Critical: > 95% of max connections

---

### 6. Request Duration

**Metric Name**: `nginx_http_request_duration_seconds`

**Description**: HTTP request processing time

**Query Examples**:
```promql
# Average request duration
rate(nginx_http_request_duration_seconds_sum[5m]) / 
rate(nginx_http_request_duration_seconds_count[5m])

# 95th percentile request duration
histogram_quantile(0.95, rate(nginx_http_request_duration_seconds_bucket[5m]))
```

**Alert Threshold**:
- Warning: p95 > 1 second
- Critical: p95 > 3 seconds

---

## WordPress Application Metrics

### 7. PHP-FPM Process Count

**Metric Name**: `php_fpm_process_count`

**Description**: Number of active PHP-FPM worker processes

**Alert Threshold**:
- Warning: All workers busy
- Critical: Process manager failing to spawn workers

---

### 8. WordPress Response Time

**Metric Name**: Derived from Nginx request duration for WordPress endpoints

**Query Examples**:
```promql
# Average WordPress response time
avg(rate(nginx_http_request_duration_seconds_sum{path=~"/wp-.*"}[5m]) / 
    rate(nginx_http_request_duration_seconds_count{path=~"/wp-.*"}[5m]))
```

---

## MySQL Database Metrics

### 9. MySQL Connection Count

**Metric Name**: `mysql_global_status_threads_connected`

**Description**: Number of currently open connections

**Alert Threshold**:
- Warning: > 80% of max_connections
- Critical: > 95% of max_connections

---

### 10. Query Execution Time

**Metric Name**: `mysql_global_status_slow_queries`

**Description**: Number of slow queries (> 2 seconds)

**Query Examples**:
```promql
# Slow query rate
rate(mysql_global_status_slow_queries[5m])
```

**Alert Threshold**:
- Warning: > 10 slow queries/minute
- Critical: > 50 slow queries/minute

---

### 11. Database Size

**Metric Name**: `mysql_info_schema_table_size_bytes`

**Description**: Total database size in bytes

**Visualization**: Gauge showing current size with trend line

---

## Kubernetes Metrics

### 12. Pod Restart Count

**Metric Name**: `kube_pod_container_status_restarts_total`

**Description**: Number of times a pod has restarted

**Query Examples**:
```promql
# Pods with recent restarts
kube_pod_container_status_restarts_total{namespace="wordpress"} > 0

# Restart rate
rate(kube_pod_container_status_restarts_total{namespace="wordpress"}[1h])
```

**Alert Threshold**:
- Warning: > 3 restarts in 1 hour
- Critical: > 10 restarts in 1 hour

---

### 13. Pod Status

**Metric Name**: `kube_pod_status_phase`

**Description**: Current phase of the pod (Running, Pending, Failed, etc.)

**Alert Condition**: Any pod not in "Running" state for > 5 minutes

---

### 14. Persistent Volume Usage

**Metric Name**: `kubelet_volume_stats_used_bytes` / `kubelet_volume_stats_capacity_bytes`

**Description**: Disk usage percentage for PVCs

**Alert Threshold**:
- Warning: > 80% disk usage
- Critical: > 90% disk usage

---

## Network Metrics

### 15. Network Traffic

**Metric Names**:
- `container_network_receive_bytes_total`: Bytes received
- `container_network_transmit_bytes_total`: Bytes transmitted

**Query Examples**:
```promql
# Incoming traffic rate (MB/s)
rate(container_network_receive_bytes_total{pod=~"wordpress-.*"}[5m]) / 1024 / 1024

# Outgoing traffic rate (MB/s)
rate(container_network_transmit_bytes_total{pod=~"wordpress-.*"}[5m]) / 1024 / 1024
```

---

## Grafana Dashboard Panels

The WordPress monitoring dashboard includes:

1. **Overview Panel**
   - Total requests (last 24h)
   - Error rate (current)
   - Average response time
   - Active connections

2. **Traffic Panel**
   - Request rate graph
   - Status code distribution
   - Network I/O

3. **Performance Panel**
   - CPU utilization per pod
   - Memory utilization per pod
   - Request duration histogram

4. **Errors Panel**
   - 5xx error rate
   - 4xx error rate
   - Error log stream

5. **Database Panel**
   - MySQL connections
   - Slow queries
   - Database size

## Access Information

- **Prometheus**: `kubectl port-forward -n monitoring svc/prometheus 9090:9090`
  - URL: http://localhost:9090

- **Grafana**: `kubectl port-forward -n monitoring svc/grafana 3000:3000`
  - URL: http://localhost:3000
  - Username: admin
  - Password: admin123

## Alerting Rules

All critical metrics have associated alert rules configured in Prometheus AlertManager:
- High CPU/Memory usage
- High error rates
- Pod restarts
- Service unavailability
- Slow response times

Alerts can be configured to send notifications via:
- Email
- Slack
- PagerDuty
- Webhook

## Metric Retention

- **Prometheus**: 15 days
- **Grafana**: Unlimited (uses Prometheus as data source)

## Best Practices

1. **Baseline Metrics**: Establish normal baseline values during low-traffic periods
2. **Capacity Planning**: Monitor trends to predict resource requirements
3. **Alert Fatigue**: Tune thresholds to minimize false positives
4. **Dashboard Organization**: Group related metrics for quick troubleshooting
5. **Regular Review**: Weekly review of metrics to identify optimization opportunities
