#!/bin/bash

echo "Start the deployment of the UDP Health Check Server pod/service."

kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/02.udp_health_check-nlb_oci/kubernetes/01.create__Namespace.yaml && \

#kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/02.udp_health_check-nlb_oci/kubernetes/02.udp-health-check-server-1700__Deployment.yaml && \
#kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/02.udp_health_check-nlb_oci/kubernetes/03.udp-health-check-server-1700__Service.yaml && \
kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/02.udp_health_check-nlb_oci/kubernetes/04.udp-health-check-server-1700__DaemonSet.yaml && \
#kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/02.udp_health_check-nlb_oci/kubernetes/05.udp-health-check-server-1700__Service-DaemonSet.yaml && \

#kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/02.udp_health_check-nlb_oci/kubernetes/06.udp-health-check-server-1710__Deployment.yaml && \
#kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/02.udp_health_check-nlb_oci/kubernetes/07.udp-health-check-server-1710__Service.yaml && \
kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/02.udp_health_check-nlb_oci/kubernetes/08.udp-health-check-server-1710__DaemonSet.yaml && \
#kubectl apply -f ~/Apps/OracleCloud/01.k8s-on-arm-oci-always-free_standart/02.udp_health_check-nlb_oci/kubernetes/09.udp-health-check-server-1710__Service-DaemonSet.yaml && \

echo "Successfully completed deployment of UDP Health Check Server pod/service."
