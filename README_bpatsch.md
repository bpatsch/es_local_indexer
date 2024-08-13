# Introduction

This page describes the installation of ES Local indexer to search throuth the local "stories" archive.


# Installation
## Elasticsearch
- Open https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html
- follow instructions for Docker image
- if you use podman: `alias docker='podman'`
- set environment variables to disable SSL:
```
xpack.security.enabled: false
xpack.security.enrollment.enabled: false
```

## ES Local Indexer
- Clone repo: `git clone git@github.com:bpatsch/es_local_indexer.git`
- Remove virtual environment: `cd es_local_indexer; rm -rf venv`
- Install new virtual environment: `python3 -m venv venv`
- `source venv/bin/activate`
- Confirm correct installation: `which pip` - should result in (...)/venv/bin/pip
- Install dependencies: `pip install -r requirements.txt `

## Index local documents
- Ingest local documents into Elasticsearch: `python3 indexing_app.py -p /data/surf/.plain/stories/ -i stories`
- Query current index: `curl -u elastic:elastic 'http://localhost:9200/_cat/indices?v'`

# Run


