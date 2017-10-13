import json


def load(filename):
    with open(filename) as f:
        return json.load(f)


def write(filename, content):
    if not filename.endswith('.json'):
        filename = '%s.json' % filename
    with open(filename, 'w') as f:
        f.write(json.dumps(content))
