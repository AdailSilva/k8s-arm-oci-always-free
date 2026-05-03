package br.com.adailsilva.k8sdashboard.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class NodeDto {
    private String  name;
    private String  status;          // Ready / NotReady
    private String  role;            // control-plane / worker
    private String  version;
    private String  internalIp;
    private String  os;
    private String  architecture;
    private String  containerRuntime;
    private String  age;
    private Long    cpuCapacityMillicores;
    private Long    memCapacityBytes;
    private Long    cpuUsageMillicores;
    private Long    memUsageBytes;
    private Integer cpuPercent;      // 0-100
    private Integer memPercent;      // 0-100
    private Integer diskPercent;     // placeholder — not from Metrics API
}
