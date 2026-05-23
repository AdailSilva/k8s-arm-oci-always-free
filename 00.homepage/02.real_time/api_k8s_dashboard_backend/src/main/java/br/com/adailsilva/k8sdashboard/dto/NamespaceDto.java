package br.com.adailsilva.k8sdashboard.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Data;

import java.util.Map;

@Data
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class NamespaceDto {
    private String              name;
    private String              status;
    private String              age;
    private Map<String, String> labels;
}
