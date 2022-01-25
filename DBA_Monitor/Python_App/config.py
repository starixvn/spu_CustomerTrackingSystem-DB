import json

config = {}

with open('/var/cts/monitor/config.json') as f:
    config = json.load(f)