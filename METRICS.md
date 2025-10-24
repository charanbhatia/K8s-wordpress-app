# Metrics Documentation

## Overview
This document outlines all required metrics for monitoring WordPress, MySQL, and Nginx components.

## Nginx Metrics

### Request Metrics
- **nginx_http_requests_total**: Total number of HTTP requests
  - Labels: status, method, path
  - Type: Counter
  - Usage: Track total request volume

- **nginx_http_request_duration_seconds**: HTTP request latency
  - Type: Histogram
  - Usage: Monitor request processing time

- **nginx_http_requests_5xx**: Total 5xx error responses
  - Type: Counter
  - Usage: Track server errors

- **nginx_http_requests_4xx**: Total 4xx error responses
  - Type: Counter
  - Usage: Track client errors

### Connection Metrics
- **nginx_connections_active**: Active client connections
  - Type: Gauge
  - Usage: Monitor concurrent connections

- **nginx_connections_reading**: Connections reading request
  - Type: Gauge
  - Usage: Monitor read operations

- **nginx_connections_writing**: Connections writing response
  - Type: Gauge
  - Usage: Monitor write operations

- **nginx_connections_waiting**: Idle keepalive connections
  - Type: Gauge
  - Usage: Monitor connection pooling

## WordPress (PHP-FPM) Metrics

### Process Metrics
- **phpfpm_accepted_connections**: Total accepted connections
  - Type: Counter
  - Usage: Track connection acceptance rate

- **phpfpm_active_processes**: Currently active processes
  - Type: Gauge
  - Usage: Monitor process utilization

- **phpfpm_idle_processes**: Currently idle processes
  - Type: Gauge
  - Usage: Monitor available capacity

- **phpfpm_max_active_processes**: Maximum active processes reached
  - Type: Gauge
  - Usage: Track peak utilization

### Request Metrics
- **phpfpm_slow_requests**: Slow requests count
  - Type: Counter
  - Usage: Identify performance issues

- **phpfpm_request_duration**: Request processing duration
  - Type: Histogram
  - Usage: Monitor PHP execution time

## MySQL Metrics

### Connection Metrics
- **mysql_global_status_threads_connected**: Currently open connections
  - Type: Gauge
  - Usage: Monitor active connections

- **mysql_global_status_threads_running**: Currently running threads
  - Type: Gauge
  - Usage: Monitor query execution

- **mysql_global_status_max_used_connections**: Max connections used
  - Type: Gauge
  - Usage: Track connection peaks

### Query Metrics
- **mysql_global_status_queries**: Total queries executed
  - Type: Counter
  - Usage: Track query volume

- **mysql_global_status_slow_queries**: Slow queries count
  - Type: Counter
  - Usage: Identify performance issues

- **mysql_global_status_questions**: Client statements count
  - Type: Counter
  - Usage: Track client activity

### Performance Metrics
- **mysql_global_status_innodb_buffer_pool_read_requests**: Buffer pool reads
  - Type: Counter
  - Usage: Monitor cache efficiency

- **mysql_global_status_innodb_buffer_pool_reads**: Disk reads
  - Type: Counter
  - Usage: Monitor disk I/O

- **mysql_global_status_table_locks_waited**: Table lock waits
  - Type: Counter
  - Usage: Identify locking issues

## Kubernetes Metrics

### Pod Metrics
- **container_cpu_usage_seconds_total**: CPU usage per container
  - Type: Counter
  - Usage: Monitor CPU consumption

- **container_memory_usage_bytes**: Memory usage per container
  - Type: Gauge
  - Usage: Monitor memory consumption

- **container_network_receive_bytes_total**: Network bytes received
  - Type: Counter
  - Usage: Monitor inbound traffic

- **container_network_transmit_bytes_total**: Network bytes transmitted
  - Type: Counter
  - Usage: Monitor outbound traffic

### Resource Metrics
- **kube_pod_container_resource_requests**: Resource requests
  - Type: Gauge
  - Usage: Track resource allocation

- **kube_pod_container_resource_limits**: Resource limits
  - Type: Gauge
  - Usage: Track resource constraints

- **kube_pod_status_phase**: Pod status
  - Type: Gauge
  - Usage: Monitor pod health

## Alert Thresholds

### Critical Alerts
- Pod CPU usage > 80% for 5 minutes
- Pod memory usage > 80% for 5 minutes
- 5xx error rate > 5% for 2 minutes
- Pod down for 1 minute
- Disk space < 10% for 5 minutes

### Warning Alerts
- Request latency p95 > 1 second for 5 minutes
- MySQL slow queries > 10/minute
- High connection count > 80% max

## Monitoring Best Practices

1. Set appropriate scrape intervals (15s recommended)
2. Use recording rules for complex queries
3. Implement retention policies (15 days minimum)
4. Configure alerting channels (email, Slack, PagerDuty)
5. Create dashboards for different stakeholders
6. Regular review of alert rules and thresholds
7. Document metric semantics and usage
8. Monitor monitoring system itself
