#!/bin/bash

echo "Start deploying the Metrics Server component pod/service."

#kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/01.metrics_server/kubernetes/00.metrics-server__Full.yaml && \

#kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/01.metrics_server/kubernetes/01.metrics-server__Namespace.yaml && \

kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/01.metrics_server/kubernetes/02.metrics-server__ServiceAccount.yaml && \

kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/01.metrics_server/kubernetes/03.metrics-server__ClusterRole.yaml && \

kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/01.metrics_server/kubernetes/04.metrics-server__RoleBinding.yaml && \

kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/01.metrics_server/kubernetes/05.metrics-server__ClusterRoleBinding.yaml && \

kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/01.metrics_server/kubernetes/06.metrics-server__Deployment.yaml && \

kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/01.metrics_server/kubernetes/07.metrics-server__Service.yaml && \

kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/01.metrics_server/kubernetes/08.metrics-server__ApiService.yaml && \

echo "Deploying completed successfully into the Metrics Server Components pod/service."
