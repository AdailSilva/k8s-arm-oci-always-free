package br.com.adailsilva.k8sdashboard.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.Map;

@Data
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ServiceDto {
    private String              name;
    private String              namespace;
    private String              type;        // ClusterIP / NodePort / LoadBalancer / ExternalName
    private String              clusterIp;
    private List<String>        externalIps;
    private List<PortDto>       ports;
    private String              age;
    private Map<String, String> selector;
}
