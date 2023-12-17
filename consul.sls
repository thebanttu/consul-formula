{%- set roles = salt['grains.get']('roles') -%}
{%- set hostname = salt['grains.get']('nodename') -%}
{% if "metrics" in roles %}
{%- set default_service_name = "prometheus" -%}
{%- set default_service_port = 9090 -%}
{% elif "logging" in roles %}
{%- set default_service_name = "rsyslog" -%}
{%- set default_service_port = 10514 -%}
{% elif "load-balancer" in roles %}
{%- set default_service_name = "load-balancer" -%}
{%- set default_service_port = 443 -%}
{% elif "api" in roles %}
{%- set default_service_name = "api" -%}
{%- set default_service_port = 1616 -%}
{% elif "web" in roles %}
{%- set default_service_name = "web" -%}
{%- set default_service_port = 8009 -%}
{% elif "admin-portal" in roles %}
{%- set default_service_name = "admin-portal" -%}
{%- set default_service_port = 80 -%}
{% elif "queue" in roles %}
{%- set default_service_name = "rabbbitmq" -%}
{%- set default_service_port = 5672 -%}
{% endif %}
{%- set ip = salt['grains.get']('ipv4')[0] -%}
{%- set lb_ip = "10.132.0.2" -%}
{%- set node_type = salt['grains.get']('ConsulNodeType') -%}
{%- set dc = salt['cmd.shell']('cat /root/.data_center') -%}
{%- set leader_ip = "10.42.8.2" -%}

# -*- coding: utf-8 -*-
# vim: ft=yaml
---
consul:
  # Start Consul agent service and enable it at boot time
  service: true

  # Set user and group for Consul config files and running service
  user: consul
  group: consul

  version: 1.9.0
  download_host: releases.hashicorp.com

  config:
    {% if node_type == "server" %}
    server: true
    {% else %}
    server: false
    {% endif %}
    node_name: {{ hostname }}
    bind_addr: {{ ip }}
    disable_keyring_file: true
    disable_host_node_id: true
    enable_local_script_checks: true
    enable_script_checks: true
    enable_debug: true

    datacenter: {{ dc }}

    encrypt: "pAAc5HOPD3LDzcG6KgOR8lEFMJsamu1G"
    {% if "metrics" in roles %}
    bootstrap: true
    {% endif %}
    {% if node_type == "server" %}
    bootstrap_expect: 1
    {% endif %}
    retry_interval: 15s
    retry_join:
      - {{ leader_ip }}
      - {{ lb_ip }}

    ui_config:
      enabled: true
    log_level: info
    data_dir: /var/consul
    telemetry:
      prometheus_retention_time: 480h
      disable_hostname: true

  register:
    {% if "apps" not in roles %}
    - name: {{ default_service_name }}
      port: {{ default_service_port }}
      checks:
        - name: check-default-service
          args:
            - /usr/local/bin/check_port
            - "{{ default_service_port }}"
          interval: 10s
    {% endif %}
    - name: consul-exporter
      port: 9107
      checks:
        - name: check-consul-exporter
          args:
            - /usr/local/bin/check_port
            - "9107"
          interval: 10s
    - name: node-exporter
      port: 9100
      checks:
        - name: check-node-exporter
          args:
            - /usr/local/bin/check_port
            - "9100"
          interval: 10s
    {% if "metrics" in roles %}
    - name: grafana
      port: 3000
      checks:
        - name: check-service
          args:
            - /usr/local/bin/check_port
            - "3000"
          interval: 10s
    - name: prometheus-alertmanager
      port: 9093
      checks:
        - name: check-service
          args:
            - /usr/local/bin/check_port
            - "9093"
          interval: 10s
    {% elif "logging" in roles %}
    - name: loki
      port: 3100
      checks:
        - name: check-loki-service
          args:
            - /usr/local/bin/check_port
            - "3100"
          interval: 10s
    - name: promtail
      port: 9080
      checks:
        - name: check-service
          args:
            - /usr/local/bin/check_port
            - "9080"
          interval: 10s
    {% elif "load-balancer" in roles %}
    - name: haproxy-exporter
      port: 9101
      checks:
        - name: check-haproxy-exporter
          args:
            - /usr/local/bin/check_port
            - "9101"
          interval: 10s
    {% elif "api" in roles %}
    - name: nginx-exporter
      port: 9113
      checks:
        - name: check-nginx-exporter
          args:
            - /usr/local/bin/check_port
            - "9113"
          interval: 10s
    - name: c2b
      port: 8000
      checks:
        - name: check-service
          args:
            - /usr/local/bin/check_port
            - "8000"
          interval: 10s
    - name: mo-consumer
      port: 8008
      checks:
        - name: check-service
          args:
            - /usr/local/bin/check_port
            - "8008"
          interval: 10s
    - name: queue-consumer
      port: 9000
      checks:
        - name: check-service
          args:
            - /usr/local/bin/check_port
            - "9000"
          interval: 10s
    {% elif "web" in roles %}
    - name: mobile-web
      port: 8005
      checks:
        - name: check-service
          args:
            - /usr/local/bin/check_port
            - "8005"
          interval: 10s
    - name: nginx-exporter
      port: 9113
      checks:
        - name: check-service
          args:
            - /usr/local/bin/check_port
            - "9113"
          interval: 10s
    {% elif "apps" in roles %}
    - name: biko-betradar-feeds-fetcher
      port: 1616
      checks:
        - name: check-biko-betradar-feeds-fetcher
          args:
            - check_app
            - BetradarFeedsFetcher.jar
          interval: 10s

    - name: biko-live-odds-consumer
      port: 1616
      checks:
        - name: check-biko-live-odds-consumer
          args:
            - check_app
            - BetradarCombinedLiveOddsConsumer.2.0.52.1-jar-with-dependencies.jar
          interval: 10s

    - name: biko-betradar-outcome-processor
      port: 1616
      checks:
        - name: check-biko-betradar-outcome-processor
          args:
            - check_app
            - BetradarOutcomeProcessor-2.0.2.jar
          interval: 10s

    - name: biko-outcome-processor
      port: 1616
      checks:
        - name: check-biko-outcome-processor
          args:
            - check_app
            - BikoOutcomeProcessor.live.jar
          interval: 10s

    - name: biko-mts-processor
      port: 1616
      checks:
        - name: check-biko-mts-processor
          args:
            - check_app
            - MTSProcessor.2.3.2.0-jar-with-dependencies.jar
          interval: 10s
    - name: biko-inbox-consumer
      port: 1616
      checks:
        - name: check-biko-inbox-consumer
          args:
            - check_app
            - inboxConsumer-0.0.1-SNAPSHOT-jar-with-dependencies.jar
          interval: 10s
    {% elif "queue" in roles %}
    - name: rabbitmq-exporter
      port: 9419
      checks:
        - name: check-service
          args:
            - /usr/local/bin/check_port
            - "9419"
          interval: 10s
    {% elif "admin-portal" in roles %}
    - name: nginx-exporter
      port: 9113
      checks:
        - name: check-service
          args:
            - /usr/local/bin/check_port
            - "9113"
          interval: 10s
    {% endif %}
  # scripts:
  #   - source: salt://files/consul/check_redis.py
  #     name: /usr/local/share/consul/check_redis.py
  #     context:
  #       port: 6379

consul_template:
  # Start consul-template daemon and enable it at boot time
  service: true

  config:
    consul: 127.0.0.1:8500
    log_level: info

  tmpl:
    - name: all-services
      source: salt://consul-template/files/all-services.ctmpl
      config:
        template:
          source: /etc/consul-template/tmpl-source/all-services.ctmpl
          destination: /root/.all-services.txt
          command: 'echo "Template ran at: "$(date) >> /root/.all-services.txt'
