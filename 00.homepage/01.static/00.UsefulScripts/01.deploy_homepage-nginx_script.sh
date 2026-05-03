#!/bin/bash

echo "Start deploying the Homepage component pod/service."

kubectl apply -f /home/adailsilva/Apps/OracleCloud/02.k8s-on-arm-oci-always-free_full/00.homepage/01.static/kubernetes01.homepage-nginx__Namespace && \
kubectl apply -f /home/adailsilva/Apps/OracleCloud/02.k8s-on-arm-oci-always-free_full/00.homepage/01.static/kubernetes02.homepage-nginx__Deployment.yaml && \
kubectl apply -f /home/adailsilva/Apps/OracleCloud/02.k8s-on-arm-oci-always-free_full/00.homepage/01.static/kubernetes03.homepage-nginx__Service.yaml && \
kubectl apply -f /home/adailsilva/Apps/OracleCloud/02.k8s-on-arm-oci-always-free_full/00.homepage/01.static/kubernetes04.homepage-nginx-cert-manager__v1.12.3__Components_Full.yaml && \
kubectl apply -f /home/adailsilva/Apps/OracleCloud/02.k8s-on-arm-oci-always-free_full/00.homepage/01.static/kubernetes05.homepage-nginx-letsencrypt-issuer_with_e-mail_ACME_registration__ClusterIssuer.yaml && \
kubectl apply -f /home/adailsilva/Apps/OracleCloud/02.k8s-on-arm-oci-always-free_full/00.homepage/01.static/kubernetes06.homepage-nginx__Ingress.yaml && \

echo "Deploying completed successfully into the Homepage Components pod/service."
