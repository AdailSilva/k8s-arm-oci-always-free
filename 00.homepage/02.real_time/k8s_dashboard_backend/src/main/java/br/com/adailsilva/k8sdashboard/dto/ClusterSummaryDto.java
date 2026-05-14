package br.com.adailsilva.k8sdashboard.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ClusterSummaryDto {
    private int totalNodes;
    private int readyNodes;
    private int totalPods;
    private int runningPods;
    private int totalServices;
    private int totalIngresses;
    private int totalNamespaces;
    private String kubernetesVersion;
}
