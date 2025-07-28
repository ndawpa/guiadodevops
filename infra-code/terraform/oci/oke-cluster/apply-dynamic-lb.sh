#!/bin/bash

# Script para aplicar Dynamic Shapes em Load Balancers OCI
# Uso: ./apply-dynamic-lb.sh <service-name>

SERVICE_NAME=$1

if [ -z "$SERVICE_NAME" ]; then
    echo "Uso: $0 <service-name>"
    echo "Exemplo: $0 my-app-service"
    exit 1
fi

echo "Aplicando Dynamic Shapes no serviço: $SERVICE_NAME"

# Aplicar anotações para Dynamic Shapes
kubectl annotate service $SERVICE_NAME \
    service.beta.kubernetes.io/oci-load-balancer-shape="flexible" \
    service.beta.kubernetes.io/oci-load-balancer-shape-flex-min="10" \
    service.beta.kubernetes.io/oci-load-balancer-shape-flex-max="100" \
    service.beta.kubernetes.io/oci-load-balancer-is-private="false" \
    --overwrite

echo "Anotações aplicadas com sucesso!"
echo "Verificando status do serviço..."

kubectl get service $SERVICE_NAME

echo ""
echo "Para verificar as anotações aplicadas:"
echo "kubectl describe service $SERVICE_NAME" 