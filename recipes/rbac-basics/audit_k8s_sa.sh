# List all Service Accounts in all namespaces
#!/bin/bash

NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

for ns in $NAMESPACES; do
  echo "Checking service accounts in namespace: $ns"
  kubectl get serviceaccounts -n $ns
done