#!/bin/bash

# Script para instalar o metrics-server no cluster OKE
# Execute após o terraform apply

echo "🚀 Instalando Metrics Server..."

# Verificar se o kubectl está configurado
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não encontrado. Instale o kubectl primeiro."
    exit 1
fi

# Verificar se o cluster está acessível
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Não foi possível conectar ao cluster. Configure o kubeconfig primeiro."
    echo "💡 Execute: export KUBECONFIG=\$(terraform output -raw cluster_kubeconfig)"
    exit 1
fi

echo "✅ Cluster conectado. Instalando metrics-server..."

# Instalar metrics-server usando o manifesto oficial
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Aguardar o deployment estar pronto
echo "⏳ Aguardando o metrics-server estar pronto..."
kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system

# Verificar se está funcionando
echo "🔍 Verificando se o metrics-server está funcionando..."
kubectl get pods -n kube-system | grep metrics-server

echo "✅ Metrics Server instalado com sucesso!"
echo ""
echo "📊 Teste os comandos:"
echo "   kubectl top nodes"
echo "   kubectl top pods"
echo "   kubectl top pods -n kube-system" 