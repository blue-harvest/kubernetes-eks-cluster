#!/bin/bash

# Update DNS in values files
export KUBECONFIG=kubeconfig_$CLUSTER_NAME

# Inject pipeline variables in HELM values files
sed -i -e "s/CLUSTER_ZONE_ID/${CLUSTER_ZONE_ID}/g" ./helm/cert-manager/letsencrypt-staging.yaml
sed -i -e "s/AWS_ACCESS_KEY_ID/${AWS_ACCESS_KEY_ID}/g" ./helm/cert-manager/letsencrypt-staging.yaml

sed -i -e "s/CLUSTER_ZONE_ID/${CLUSTER_ZONE_ID}/g" ./helm/cert-manager/letsencrypt-prod.yaml
sed -i -e "s/AWS_ACCESS_KEY_ID/${AWS_ACCESS_KEY_ID}/g" ./helm/cert-manager/letsencrypt-prod.yaml

sed -i -e "s/CLUSTER_DNS_ZONE/${CLUSTER_DNS_ZONE}/g" ./helm/external-dns/external-dns-intranet.yaml
sed -i -e "s/CLUSTER_NAME/${CLUSTER_NAME}/g" ./helm/external-dns/external-dns-intranet.yaml

sed -i -e "s/CLUSTER_DNS_ZONE/${CLUSTER_DNS_ZONE}/g" ./helm/external-dns/external-dns-internet.yaml
sed -i -e "s/CLUSTER_NAME/${CLUSTER_NAME}/g" ./helm/external-dns/external-dns-internet.yaml

sed -i -e "s/CLUSTER_DNS_ZONE/${CLUSTER_DNS_ZONE}/g" ./helm/external-dns/external-dns-istio.yaml
sed -i -e "s/CLUSTER_NAME/${CLUSTER_NAME}/g" ./helm/external-dns/external-dns-istio.yaml

sed -i -e "s/CLUSTER_DNS_ZONE/${CLUSTER_DNS_ZONE}/g" ./helm/external-dns/external-dns-nginx.yaml
sed -i -e "s/CLUSTER_NAME/${CLUSTER_NAME}/g" ./helm/external-dns/external-dns-nginx.yaml

sed -i -e "s/YOUR_CLUSTER_NAME/${CLUSTER_NAME}/g" ./helm/cluster-autoscaler.yaml

sed -i -e "s/CLUSTER_DNS/${CLUSTER_DNS}/g" ./helm/nginx-ingress.yaml
sed -i -e "s/CLUSTER_DNS/${CLUSTER_DNS}/g" ./helm/nginx-ingress-internal.yaml

sed -i -e "s/CLUSTER_DNS/${CLUSTER_DNS}/g" ./helm/kubernetes-dashboard.yaml

sed -i -e "s/CLUSTER_DNS/${CLUSTER_DNS}/g" ./helm/logging/cerebro.yaml
sed -i -e "s/CLUSTER_DNS/${CLUSTER_DNS}/g" ./helm/logging/kibana.yaml

sed -i -e "s/CLUSTER_DNS/${CLUSTER_DNS}/g" ./helm/monitoring/grafana.yaml
sed -i -e "s/CLUSTER_DNS/${CLUSTER_DNS}/g" ./helm/monitoring/prometheus.yaml
sed -i -e "s/CLUSTER_DNS/${CLUSTER_DNS}/g" ./helm/istio/istio-1.0.4/values.yaml

# Install AWS Authenticator
wget -O /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iam-authenticator
chmod +x /usr/local/bin/aws-iam-authenticator

aws-iam-authenticator help

# Install Tiller
kubectl apply -f ./helm/tiller-rbac.yaml
helm init --service-account tiller --upgrade
helm repo add incubator $HELM_INCUBATOR_REPO

sleep 80

# Install Custom Storage Class
kubectl apply -f ./helm/custom-storage-class.yaml

# Install Kube DNS
kubectl apply -f ./helm/kube-dns-autoscaler.yaml

# Install Nginx Ingress Controller
helm upgrade --install nginx-ingress -f ./helm/nginx-ingress.yaml stable/nginx-ingress --namespace nginx-ingress
helm upgrade --install nginx-ingress-internal -f ./helm/nginx-ingress-internal.yaml stable/nginx-ingress --namespace nginx-ingress

# Install External DNS
kubectl create secret generic route53-config --from-literal=secret-access-key=$AWS_SECRET_ACCESS_KEY --namespace kube-system --dry-run -o yaml | kubectl apply -f -
kubectl apply -f ./helm/external-dns/external-dns-rbac.yaml

helm upgrade --install external-dns-intranet -f ./helm/external-dns/external-dns-intranet.yaml stable/external-dns --namespace kube-system
helm upgrade --install external-dns-internet -f ./helm/external-dns/external-dns-internet.yaml stable/external-dns --namespace kube-system
helm upgrade --install external-dns-nginx -f ./helm/external-dns/external-dns-nginx.yaml stable/external-dns --namespace kube-system
helm upgrade --install external-dns-istio -f ./helm/external-dns/external-dns-istio.yaml stable/external-dns --namespace kube-system

# Install Cert Manager
helm upgrade --install cert-manager -f ./helm/cert-manager/cert-manager.yaml stable/cert-manager --namespace kube-system --version v0.5.1
kubectl apply -f ./helm/cert-manager/letsencrypt-staging.yaml

# Install Dashboard
helm upgrade --install kubernetes-dashboard -f ./helm/kubernetes-dashboard.yaml stable/kubernetes-dashboard --namespace kube-system

# Install Autoscaling
helm upgrade --install metrics-server -f ./helm/metrics-server.yaml stable/metrics-server --namespace kube-system
helm upgrade --install cluster-autoscaler -f ./helm/cluster-autoscaler.yaml stable/cluster-autoscaler --namespace kube-system

# Install EFK Stack
helm upgrade --install elasticsearch -f ./helm/logging/elasticsearch.yaml incubator/elasticsearch --namespace logging
helm upgrade --install curator -f ./helm/logging/curator.yaml incubator/elasticsearch-curator --namespace logging
helm upgrade --install fluentd -f ./helm/logging/fluentd.yaml stable/fluentd-elasticsearch --namespace logging
helm upgrade --install cerebro -f ./helm/logging/cerebro.yaml stable/cerebro --namespace logging
helm upgrade --install kibana -f ./helm/logging/kibana.yaml stable/kibana --namespace logging

# Install Prometheus
helm upgrade --install prometheus -f ./helm/monitoring/prometheus.yaml stable/prometheus --namespace monitoring

# Install Grafana
kubectl create configmap default-dashboards --from-file=./helm/monitoring/default-dashboards --namespace monitoring --dry-run -o yaml | kubectl apply -f -
kubectl create configmap istio-dashboards --from-file=./helm/monitoring/istio-dashboards --namespace monitoring --dry-run -o yaml | kubectl apply -f -
kubectl create configmap istio-system-dashboards --from-file=./helm/monitoring/istio-system-dashboards --namespace monitoring --dry-run -o yaml | kubectl apply -f -
helm upgrade --install grafana -f ./helm/monitoring/grafana.yaml stable/grafana --namespace monitoring

# Clean up previous Istio deployments
kubectl delete job --ignore-not-found=true istio-security-post-install -n istio-system
kubectl delete  --ignore-not-found=true -f ./helm/istio/istio-1.0.4/templates/crds.yaml

# Install Istio
kubectl label namespace default istio-injection=enabled --overwrite=true
helm upgrade --install istio ./helm/istio/istio-1.0.4 --namespace istio-system
kubectl apply -f ./helm/istio/fluentd-istio.yaml
