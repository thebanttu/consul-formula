{%- set name = "default-node" -%}
{%- set ip = salt['grains.get']('ipv4')[0] -%}
{%- set rand_str = salt['random.get_str'](length=3,punctuation=false) -%}
{%- set default_service_port = 8008 -%}
{%- set dc = salt['cmd.shell']('cat /root/.data_center') -%}
{%- set leader_ip = salt['cmd.shell']('cat /root/.leader_ip') -%}
{
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
    server: false
    node_name: {{ name }}-{{ rand_str }}
    bind_addr: {{ ip }}
    disable_keyring_file: true
    disable_host_node_id: true
    enable_local_script_checks: true
    enable_script_checks: true
    enable_debug: true

    datacenter: {{ dc }}

    encrypt: "pAAc5HOPD3LDzcG6KgOR8lEFMJsamu1G"

    bootstrap_expect: 0
    retry_interval: 15s
    retry_join:
      - {{ leader_ip }}

    ui_config:
      enabled: true
    log_level: info
    data_dir: /var/consul

  register:
    - name: dummy-service
      port: {{ default_service_port }}
      checks:
        - name: check-service
          args:
            - nc
            - -vz
            - {{ ip }}
            - "{{ default_service_port }}"
          interval: 10s

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
          command: echo "Template ran at: "$(date) >> /root/.all-services.txt
