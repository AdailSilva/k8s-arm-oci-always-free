package br.com.adailsilva.k8sdashboard.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class PodDto {
    private String       name;
    private String       namespace;
    private String       nodeName;
    private String       status;   // Running / Pending / Failed / Succeeded / CrashLoopBackOff
    private String       phase;
    private int          ready;
    private int          total;
    private int          restarts;
    private String       age;
    private String       image;    // first container image
    private List<String> images;   // all container images
    private String       podIp;
}
