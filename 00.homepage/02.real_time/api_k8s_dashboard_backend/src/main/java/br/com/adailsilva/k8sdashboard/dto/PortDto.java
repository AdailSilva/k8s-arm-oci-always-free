package br.com.adailsilva.k8sdashboard.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class PortDto {
    private String  name;
    private Integer port;
    private Integer targetPort;
    private Integer nodePort;
    private String  protocol;
}
