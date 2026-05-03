package br.com.adailsilva.k8sdashboard.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class IngressDto {
    private String              name;
    private String              namespace;
    private String              ingressClass;
    private List<IngressRuleDto> rules;
    private List<String>        addresses;
    private boolean             tls;
    private String              age;
}
