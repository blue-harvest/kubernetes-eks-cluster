#!/bin/bash

export KUBECONFIG=kubeconfig_$CLUSTER_NAME

wget -O /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iam-authenticator

chmod +x /usr/local/bin/aws-iam-authenticator
aws-iam-authenticator help

helm init --client-only

kubectl delete -f ./helm/istio/istio-1.0.4/templates/crds.yaml -n istio-system

helm del --purge istio
helm del --purge nginx-ingress
helm del --purge nginx-ingress-internal
helm del --purge external-dns-intranet
helm del --purge external-dns-internet
helm del --purge external-dns-nginx
helm del --purge cert-manager
helm del --purge kubernetes-dashboard
helm del --purge metrics-server
helm del --purge cluster-autoscaler
helm del --purge curator
helm del --purge fluentd
helm del --purge cerebro

kubectl delete sts -l app=elasticsearch --namespace logging
kubectl delete sts -l app=grafana --namespace monitoring
kubectl delete sts -l app=prometheus --namespace monitoring

sleep 60

kubectl delete pvc -l app=elasticsearch --namespace logging

sleep 180