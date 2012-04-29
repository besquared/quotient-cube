# Flexible QC-Tree Layout in a KV-Store

prefix-meta => {
  'dimensions': {
    'store': 'string',
    'product', 'string',
    'season', 'string'
  },
  
  'measures': {
    'total_sales', 'number',
    'average_sales', 'number',
    'users', 'hyperloglog(11)', // could also be p4delta for non-probabilistic cubes
  }
}

prefix-root => {
  'links': {
    'store': [{l: 'S1', r: <node-id>}, {l: 'S2', r: <node-id>}],
    'product': [{l: 'P1', r: <node-id>}, {l: 'P2', r: <node-id>}],
    'season': [{l: 's', r: <node-id>}, {l: 'f', r: <node-id>}]
  },
  
  'data': {
    'total_sales': 7.10,
    'average_sales', 3.10
    'users': <prefix-root-users>
  }
}