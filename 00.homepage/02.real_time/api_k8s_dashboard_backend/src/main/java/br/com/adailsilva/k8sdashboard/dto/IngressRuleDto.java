package br.com.adailsilva.k8sdashboard.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class IngressRuleDto {
    private String              host;
    private List<IngressPathDto> paths;
}
