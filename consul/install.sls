# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as consul with context %}

consul-dep-unzip:
  pkg.installed:
    - name: {{ 'app-arch/unzip' if grains.os_family == 'Gentoo' else 'unzip' }}

consul-bin-dir:
  file.directory:
    - name: {{ consul.bin_dir }}
    - makedirs: True

# Create consul user
consul-group:
  group.present:
    - name: {{ consul.group }}
    {% if consul.get('group_gid', None) != None -%}
    - gid: {{ consul.group_gid }}
    {%- endif %}

consul-user:
  user.present:
    - name: {{ consul.user }}
    {% if consul.get('user_uid', None) != None -%}
    - uid: {{ consul.user_uid }}
    {% endif -%}
    - groups:
      - {{ consul.group }}
    - home: {{ salt['user.info'](consul.user)['home']|default(consul.config.data_dir) }}
    - createhome: False
    - system: True
    - require:
      - group: consul-group

# Create directories
consul-config-dir:
  file.directory:
    - name: {{ consul.config_dir }}
    - user: {{ consul.user }}
    - group: {{ consul.group }}
    - mode: '0750'

consul-data-dir:
  file.directory:
    - name: {{ consul.config.data_dir }}
    - makedirs: True
    - user: {{ consul.user }}
    - group: {{ consul.group }}
    - mode: '0750'

# Install agent
consul-download:
  file.managed:
    - name: /tmp/consul_{{ consul.version }}_{{ grains.kernel | lower }}_{{ consul.arch }}.zip
    - source: https://{{ consul.download_host }}/consul/{{ consul.version }}/consul_{{ consul.version }}_{{ grains.kernel | lower }}_{{ consul.arch }}.zip
    - source_hash: https://releases.hashicorp.com/consul/{{ consul.version }}/consul_{{ consul.version }}_SHA256SUMS
    - unless: test -f {{ consul.bin_dir ~ 'consul-' ~ consul.version }}

consul-extract:
  cmd.run:
    - name: unzip /tmp/consul_{{ consul.version }}_{{ grains.kernel | lower }}_{{ consul.arch }}.zip -d /tmp
    - onchanges:
      - file: consul-download

consul-install:
  file.rename:
    - name: {{ consul.bin_dir ~ 'consul-' ~ consul.version }}
    - source: /tmp/consul
    - require:
      - file: {{ consul.bin_dir }}
    - watch:
      - cmd: consul-extract

consul-clean:
  file.absent:
    - name: /tmp/consul_{{ consul.version }}_{{ grains.kernel | lower }}_{{ consul.arch }}.zip
    - watch:
      - file: consul-install

consul-link:
  file.symlink:
    - target: consul-{{ consul.version }}
    - name: {{ consul.bin_dir ~ 'consul' }}
    - watch:
      - file: consul-install

install-check-app-script:
  file.managed:
    - name: /usr/local/bin/check_app
    - source: salt://consul/files/check_app.py
    - mode: 0755
