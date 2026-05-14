#!/bin/bash

echo "Start destruction of Homepage Component Pod/Service."

kubectl delete -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/02.real_time/kubernetes/09.homepage-nginx__Ingress.yaml && \
#kubectl delete -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/02.real_time/kubernetes/08.homepage-nginx-letsencrypt-issuer_with_e-mail_ACME_registration__ClusterIssuer.yaml && \
#kubectl delete -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/02.real_time/kubernetes/07.homepage-nginx-cert-manager__v1.12.3__Components_Full.yaml && \
kubectl delete -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/02.real_time/kubernetes/06.homepage-nginx__Frontend_Service.yaml && \
kubectl delete -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/02.real_time/kubernetes/05.homepage-nginx__Frontend_Deployment.yaml && \
kubectl delete -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/02.real_time/kubernetes/04.homepage-nginx__Backend_Service.yaml && \
kubectl delete -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/02.real_time/kubernetes/03.homepage-nginx__Backend_Deployment.yaml && \
kubectl delete -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/02.real_time/kubernetes/02.homepage-nginx__RBAC.yaml && \
kubectl delete -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/00.homepage/02.real_time/kubernetes/01.create__Namespace.yaml && \

echo "Successfully completed destruction of Homepage Components pod/service."
