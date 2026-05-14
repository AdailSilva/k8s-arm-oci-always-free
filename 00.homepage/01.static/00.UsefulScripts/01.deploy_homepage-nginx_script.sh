#!/bin/bash

echo "Start deploying the Homepage component pod/service."

kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/01.static/kubernetes/01.create__Namespace.yaml && \
kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/01.static/kubernetes/02.homepage-nginx__Deployment.yaml && \
kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/01.static/kubernetes/03.homepage-nginx__Service.yaml && \
#kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/01.static/kubernetes/04.homepage-nginx-cert-manager__v1.12.3__Components_Full.yaml && \
#kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/01.static/kubernetes/05.homepage-nginx-letsencrypt-issuer_with_e-mail_ACME_registration__ClusterIssuer.yaml && \
kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/01.static/kubernetes/06.homepage-nginx__Ingress.yaml && \

echo "Deploying completed successfully into the Homepage Components pod/service."
