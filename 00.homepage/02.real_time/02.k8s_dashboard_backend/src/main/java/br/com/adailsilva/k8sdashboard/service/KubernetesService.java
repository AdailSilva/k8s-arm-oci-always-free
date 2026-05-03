package br.com.adailsilva.k8sdashboard.service;

import br.com.adailsilva.k8sdashboard.dto.*;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import io.kubernetes.client.custom.NodeMetrics;
import io.kubernetes.client.custom.NodeMetricsList;
import io.kubernetes.client.custom.Quantity;
import io.kubernetes.client.openapi.ApiClient;
import io.kubernetes.client.openapi.ApiException;
import io.kubernetes.client.openapi.apis.CoreV1Api;
import io.kubernetes.client.openapi.apis.NetworkingV1Api;
import io.kubernetes.client.openapi.models.*;
import io.kubernetes.client.util.generic.GenericKubernetesApi;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class KubernetesService {

    private final CoreV1Api       coreV1Api;
    private final NetworkingV1Api networkingV1Api;
    private final ApiClient       apiClient;

    // Gson sem CustomTypeAdapterFactory — ignora campos desconhecidos do K8s 1.31+
    private static final Gson GSON = new GsonBuilder()
            .setDateFormat("yyyy-MM-dd'T'HH:mm:ssZ")
            .create();

    // ──────────────────────────────────────────────────────────────────────────
    // CLUSTER SUMMARY
    // ──────────────────────────────────────────────────────────────────────────

    public ClusterSummaryDto getClusterSummary() {
        try {
            List<JsonObject> rawNodes = listNodesRaw();
            V1PodList        podList  = coreV1Api.listPodForAllNamespaces().execute();
            V1ServiceList    svcList  = coreV1Api.listServiceForAllNamespaces().execute();
            V1NamespaceList  nsList   = coreV1Api.listNamespace().execute();
            V1IngressList    ingList  = networkingV1Api.listIngressForAllNamespaces().execute();

            int totalNodes  = rawNodes.size();
            int readyNodes  = (int) rawNodes.stream()
                    .filter(this::isNodeReady).count();
            int totalPods   = safeSize(podList.getItems());
            int runningPods = (int) safeList(podList.getItems()).stream()
                    .filter(p -> "Running".equals(Optional.ofNullable(p.getStatus())
                            .map(V1PodStatus::getPhase).orElse(""))).count();

            return ClusterSummaryDto.builder()
                    .totalNodes(totalNodes)
                    .readyNodes(readyNodes)
                    .totalPods(totalPods)
                    .runningPods(runningPods)
                    .totalServices(safeSize(svcList.getItems()))
                    .totalIngresses(safeSize(ingList.getItems()))
                    .totalNamespaces(safeSize(nsList.getItems()))
                    .build();

        } catch (ApiException e) {
            log.error("Failed to get cluster summary: {} {}", e.getCode(), e.getResponseBody());
            throw new RuntimeException("Kubernetes API error: " + e.getMessage(), e);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // NODES
    // ──────────────────────────────────────────────────────────────────────────

    public List<NodeDto> getNodes() {
        Map<String, NodeMetrics> metricsMap = fetchNodeMetrics();
        return listNodesRaw().stream()
                .map(raw -> mapNodeRaw(raw, metricsMap))
                .collect(Collectors.toList());
    }

    /**
     * Fetches nodes via raw HTTP + JsonParser to bypass the strict
     * validateJsonObject() called by V1NodeList's CustomTypeAdapterFactory,
     * which throws IllegalArgumentException for fields added in K8s 1.31+
     * (userNamespaces, recursiveReadOnlyMounts) not yet modelled in client-java.
     */
    private List<JsonObject> listNodesRaw() {
        try {
            String basePath = apiClient.getBasePath();
            OkHttpClient http = apiClient.getHttpClient();
            okhttp3.Authenticator auth = apiClient.getHttpClient().authenticator();

            Request.Builder builder = new Request.Builder()
                    .url(basePath + "/api/v1/nodes")
                    .get();

            // Inject the Bearer token from the existing client configuration
            String token = extractBearerToken();
            if (token != null) {
                builder.header("Authorization", "Bearer " + token);
            }

            try (Response response = http.newCall(builder.build()).execute()) {
                if (!response.isSuccessful() || response.body() == null) {
                    log.warn("listNodesRaw: HTTP {}", response.code());
                    return Collections.emptyList();
                }
                String body = response.body().string();
                JsonObject root = JsonParser.parseString(body).getAsJsonObject();
                JsonArray items = root.getAsJsonArray("items");
                if (items == null) return Collections.emptyList();

                List<JsonObject> nodes = new ArrayList<>();
                for (JsonElement el : items) {
                    nodes.add(el.getAsJsonObject());
                }
                return nodes;
            }
        } catch (IOException e) {
            log.error("Failed to fetch nodes via raw HTTP: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    private String extractBearerToken() {
        try {
            // The ApiClient stores authentication headers — extract the token
            List<okhttp3.Interceptor> interceptors = apiClient.getHttpClient().interceptors();
            // Fall back to reading the ServiceAccount token file directly
            java.nio.file.Path tokenPath = java.nio.file.Paths.get(
                    "/var/run/secrets/kubernetes.io/serviceaccount/token");
            if (java.nio.file.Files.exists(tokenPath)) {
                return new String(java.nio.file.Files.readAllBytes(tokenPath)).trim();
            }
            // For local dev: extract from kubeconfig via apiClient's access token
            Object creds = apiClient.getAuthentications().get("BearerToken");
            if (creds instanceof io.kubernetes.client.openapi.auth.HttpBearerAuth bearer) {
                return bearer.getBearerToken();
            }
        } catch (Exception e) {
            log.debug("Could not extract bearer token: {}", e.getMessage());
        }
        return null;
    }

    private boolean isNodeReady(JsonObject node) {
        try {
            JsonArray conditions = node.getAsJsonObject("status")
                    .getAsJsonArray("conditions");
            for (JsonElement c : conditions) {
                JsonObject cond = c.getAsJsonObject();
                if ("Ready".equals(cond.get("type").getAsString())) {
                    return "True".equals(cond.get("status").getAsString());
                }
            }
        } catch (Exception ignored) {}
        return false;
    }

    private NodeDto mapNodeRaw(JsonObject raw, Map<String, NodeMetrics> metricsMap) {
        try {
            JsonObject meta   = raw.getAsJsonObject("metadata");
            JsonObject status = raw.getAsJsonObject("status");
            JsonObject labels = meta.has("labels") ? meta.getAsJsonObject("labels") : new JsonObject();

            String name = meta.get("name").getAsString();
            String role = (labels.has("node-role.kubernetes.io/control-plane") ||
                           labels.has("node-role.kubernetes.io/master"))
                    ? "control-plane" : "worker";

            String nodeStatus = "NotReady";
            String age = "unknown";
            String version = null;
            String internalIp = null;
            String os = null;
            String arch = null;
            String runtime = null;
            long cpuCap = 0L;
            long memCap = 0L;

            if (status != null) {
                // Ready condition
                if (status.has("conditions")) {
                    for (JsonElement c : status.getAsJsonArray("conditions")) {
                        JsonObject cond = c.getAsJsonObject();
                        if ("Ready".equals(cond.get("type").getAsString()) &&
                            "True".equals(cond.get("status").getAsString())) {
                            nodeStatus = "Ready";
                        }
                    }
                }
                // Addresses
                if (status.has("addresses")) {
                    for (JsonElement a : status.getAsJsonArray("addresses")) {
                        JsonObject addr = a.getAsJsonObject();
                        if ("InternalIP".equals(addr.get("type").getAsString())) {
                            internalIp = addr.get("address").getAsString();
                        }
                    }
                }
                // Node info
                if (status.has("nodeInfo")) {
                    JsonObject info = status.getAsJsonObject("nodeInfo");
                    version = info.has("kubeletVersion") ? info.get("kubeletVersion").getAsString() : null;
                    os      = info.has("operatingSystem") ? info.get("operatingSystem").getAsString() : null;
                    arch    = info.has("architecture") ? info.get("architecture").getAsString() : null;
                    runtime = info.has("containerRuntimeVersion") ? info.get("containerRuntimeVersion").getAsString() : null;
                }
                // Capacity
                if (status.has("capacity")) {
                    JsonObject cap = status.getAsJsonObject("capacity");
                    if (cap.has("cpu"))    cpuCap = parseMillicoresStr(cap.get("cpu").getAsString());
                    if (cap.has("memory")) memCap = parseBytesStr(cap.get("memory").getAsString());
                }
            }

            // Age
            if (meta.has("creationTimestamp")) {
                try {
                    OffsetDateTime created = OffsetDateTime.parse(meta.get("creationTimestamp").getAsString());
                    age = formatAge(created);
                } catch (Exception ignored) {}
            }

            // Metrics
            NodeMetrics metrics = metricsMap.get(name);
            Long cpuUsage = null, memUsage = null;
            Integer cpuPct = null, memPct = null;
            if (metrics != null && metrics.getUsage() != null) {
                cpuUsage = parseMillicores(metrics.getUsage().getOrDefault("cpu",   new Quantity("0")));
                memUsage = parseBytes     (metrics.getUsage().getOrDefault("memory", new Quantity("0")));
                cpuPct   = cpuCap > 0 ? (int) Math.min(100, cpuUsage * 100 / cpuCap) : null;
                memPct   = memCap > 0 ? (int) Math.min(100, memUsage * 100 / memCap) : null;
            }

            return NodeDto.builder()
                    .name(name).status(nodeStatus).role(role)
                    .version(version).internalIp(internalIp)
                    .os(os).architecture(arch).containerRuntime(runtime).age(age)
                    .cpuCapacityMillicores(cpuCap).memCapacityBytes(memCap)
                    .cpuUsageMillicores(cpuUsage).memUsageBytes(memUsage)
                    .cpuPercent(cpuPct).memPercent(memPct).diskPercent(null)
                    .build();

        } catch (Exception e) {
            log.warn("Failed to map raw node: {}", e.getMessage());
            return NodeDto.builder().name("unknown").status("Unknown").role("worker").build();
        }
    }

    private long parseMillicoresStr(String s) {
        try {
            if (s.endsWith("m")) return Long.parseLong(s.replace("m", ""));
            return Long.parseLong(s) * 1000L;
        } catch (Exception e) { return 0L; }
    }

    private long parseBytesStr(String s) {
        try {
            if (s.endsWith("Ki")) return Long.parseLong(s.replace("Ki", "")) * 1024L;
            if (s.endsWith("Mi")) return Long.parseLong(s.replace("Mi", "")) * 1024L * 1024L;
            if (s.endsWith("Gi")) return Long.parseLong(s.replace("Gi", "")) * 1024L * 1024L * 1024L;
            return Long.parseLong(s);
        } catch (Exception e) { return 0L; }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // PODS
    // ──────────────────────────────────────────────────────────────────────────

    public List<PodDto> getPods(String namespace) {
        try {
            V1PodList podList = namespace != null && !namespace.isBlank()
                    ? coreV1Api.listNamespacedPod(namespace).execute()
                    : coreV1Api.listPodForAllNamespaces().execute();

            return safeList(podList.getItems()).stream()
                    .map(this::mapPod)
                    .collect(Collectors.toList());

        } catch (ApiException e) {
            log.error("Failed to list pods: {} {}", e.getCode(), e.getResponseBody());
            throw new RuntimeException("Kubernetes API error: " + e.getMessage(), e);
        }
    }

    private PodDto mapPod(V1Pod pod) {
        V1PodStatus podStatus = pod.getStatus();
        List<V1ContainerStatus> containerStatuses =
                Optional.ofNullable(podStatus).map(V1PodStatus::getContainerStatuses)
                        .orElse(Collections.emptyList());

        int ready    = (int) containerStatuses.stream().filter(cs -> Boolean.TRUE.equals(cs.getReady())).count();
        int total    = Optional.ofNullable(pod.getSpec()).map(s -> safeSize(s.getContainers())).orElse(0);
        int restarts = containerStatuses.stream().mapToInt(cs -> Optional.ofNullable(cs.getRestartCount()).orElse(0)).sum();

        List<String> images = Optional.ofNullable(pod.getSpec())
                .map(V1PodSpec::getContainers).orElse(Collections.emptyList())
                .stream().map(V1Container::getImage).filter(Objects::nonNull).collect(Collectors.toList());

        String computedStatus = computePodStatus(pod, containerStatuses);

        return PodDto.builder()
                .name(Optional.ofNullable(pod.getMetadata()).map(V1ObjectMeta::getName).orElse("unknown"))
                .namespace(Optional.ofNullable(pod.getMetadata()).map(V1ObjectMeta::getNamespace).orElse("unknown"))
                .nodeName(Optional.ofNullable(pod.getSpec()).map(V1PodSpec::getNodeName).orElse(null))
                .status(computedStatus)
                .phase(Optional.ofNullable(podStatus).map(V1PodStatus::getPhase).orElse("Unknown"))
                .ready(ready)
                .total(total)
                .restarts(restarts)
                .age(formatAge(Optional.ofNullable(pod.getMetadata())
                        .map(V1ObjectMeta::getCreationTimestamp).orElse(null)))
                .image(images.isEmpty() ? null : images.get(0))
                .images(images)
                .podIp(Optional.ofNullable(podStatus).map(V1PodStatus::getPodIP).orElse(null))
                .build();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // SERVICES
    // ──────────────────────────────────────────────────────────────────────────

    public List<ServiceDto> getServices(String namespace) {
        try {
            V1ServiceList list = namespace != null && !namespace.isBlank()
                    ? coreV1Api.listNamespacedService(namespace).execute()
                    : coreV1Api.listServiceForAllNamespaces().execute();

            return safeList(list.getItems()).stream()
                    .map(this::mapService)
                    .collect(Collectors.toList());

        } catch (ApiException e) {
            log.error("Failed to list services: {} {}", e.getCode(), e.getResponseBody());
            throw new RuntimeException("Kubernetes API error: " + e.getMessage(), e);
        }
    }

    private ServiceDto mapService(V1Service svc) {
        V1ServiceSpec spec = svc.getSpec();
        List<PortDto> ports = Optional.ofNullable(spec)
                .map(V1ServiceSpec::getPorts).orElse(Collections.emptyList()).stream()
                .map(p -> PortDto.builder()
                        .name(p.getName())
                        .port(p.getPort())
                        .targetPort(p.getTargetPort() != null
                                ? p.getTargetPort().isInteger()
                                ? p.getTargetPort().getIntValue() : null : null)
                        .nodePort(p.getNodePort())
                        .protocol(p.getProtocol())
                        .build())
                .collect(Collectors.toList());

        return ServiceDto.builder()
                .name(Optional.ofNullable(svc.getMetadata()).map(V1ObjectMeta::getName).orElse("unknown"))
                .namespace(Optional.ofNullable(svc.getMetadata()).map(V1ObjectMeta::getNamespace).orElse("unknown"))
                .type(Optional.ofNullable(spec).map(V1ServiceSpec::getType).orElse("ClusterIP"))
                .clusterIp(Optional.ofNullable(spec).map(V1ServiceSpec::getClusterIP).orElse(null))
                .externalIps(Optional.ofNullable(spec).map(V1ServiceSpec::getExternalIPs).orElse(Collections.emptyList()))
                .ports(ports)
                .age(formatAge(Optional.ofNullable(svc.getMetadata())
                        .map(V1ObjectMeta::getCreationTimestamp).orElse(null)))
                .selector(Optional.ofNullable(spec).map(V1ServiceSpec::getSelector).orElse(null))
                .build();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // INGRESSES
    // ──────────────────────────────────────────────────────────────────────────

    public List<IngressDto> getIngresses(String namespace) {
        try {
            V1IngressList list = namespace != null && !namespace.isBlank()
                    ? networkingV1Api.listNamespacedIngress(namespace).execute()
                    : networkingV1Api.listIngressForAllNamespaces().execute();

            return safeList(list.getItems()).stream()
                    .map(this::mapIngress)
                    .collect(Collectors.toList());

        } catch (ApiException e) {
            log.error("Failed to list ingresses: {} {}", e.getCode(), e.getResponseBody());
            throw new RuntimeException("Kubernetes API error: " + e.getMessage(), e);
        }
    }

    private IngressDto mapIngress(V1Ingress ing) {
        V1IngressSpec spec = ing.getSpec();

        List<IngressRuleDto> rules = Optional.ofNullable(spec)
                .map(V1IngressSpec::getRules).orElse(Collections.emptyList()).stream()
                .map(this::mapIngressRule)
                .collect(Collectors.toList());

        List<String> addresses = Optional.ofNullable(ing.getStatus())
                .map(V1IngressStatus::getLoadBalancer)
                .map(V1IngressLoadBalancerStatus::getIngress).orElse(Collections.emptyList())
                .stream().map(lb -> lb.getIp() != null ? lb.getIp() : lb.getHostname())
                .filter(Objects::nonNull).collect(Collectors.toList());

        boolean hasTls = Optional.ofNullable(spec).map(V1IngressSpec::getTls)
                .map(tls -> !tls.isEmpty()).orElse(false);

        String ingressClass = Optional.ofNullable(spec).map(V1IngressSpec::getIngressClassName).orElse(
                Optional.ofNullable(ing.getMetadata()).map(V1ObjectMeta::getAnnotations).orElse(Collections.emptyMap())
                        .get("kubernetes.io/ingress.class"));

        return IngressDto.builder()
                .name(Optional.ofNullable(ing.getMetadata()).map(V1ObjectMeta::getName).orElse("unknown"))
                .namespace(Optional.ofNullable(ing.getMetadata()).map(V1ObjectMeta::getNamespace).orElse("unknown"))
                .ingressClass(ingressClass)
                .rules(rules)
                .addresses(addresses)
                .tls(hasTls)
                .age(formatAge(Optional.ofNullable(ing.getMetadata())
                        .map(V1ObjectMeta::getCreationTimestamp).orElse(null)))
                .build();
    }

    // Extração necessária: o compilador Java não consegue inferir o tipo genérico
    // de Optional.map() quando o lambda retorna List<IngressPathDto> aninhado.
    // Separando em métodos com tipo de retorno explícito o problema é resolvido.
    private IngressRuleDto mapIngressRule(V1IngressRule r) {
        List<IngressPathDto> paths = mapIngressPaths(r.getHttp());
        return IngressRuleDto.builder()
                .host(r.getHost())
                .paths(paths)
                .build();
    }

    private List<IngressPathDto> mapIngressPaths(V1HTTPIngressRuleValue http) {
        if (http == null || http.getPaths() == null) {
            return Collections.emptyList();
        }
        return http.getPaths().stream()
                .map(p -> IngressPathDto.builder()
                        .path(p.getPath())
                        .pathType(p.getPathType())
                        .service(Optional.ofNullable(p.getBackend())
                                .map(V1IngressBackend::getService)
                                .map(V1IngressServiceBackend::getName)
                                .orElse(null))
                        .servicePort(Optional.ofNullable(p.getBackend())
                                .map(V1IngressBackend::getService)
                                .map(V1IngressServiceBackend::getPort)
                                .map(V1ServiceBackendPort::getNumber)
                                .orElse(null))
                        .build())
                .collect(Collectors.toList());
    }

    // ──────────────────────────────────────────────────────────────────────────
    // NAMESPACES
    // ──────────────────────────────────────────────────────────────────────────

    public List<NamespaceDto> getNamespaces() {
        try {
            V1NamespaceList list = coreV1Api.listNamespace().execute();
            return safeList(list.getItems()).stream()
                    .map(ns -> NamespaceDto.builder()
                            .name(Optional.ofNullable(ns.getMetadata()).map(V1ObjectMeta::getName).orElse("unknown"))
                            .status(Optional.ofNullable(ns.getStatus()).map(V1NamespaceStatus::getPhase).orElse("Unknown"))
                            .age(formatAge(Optional.ofNullable(ns.getMetadata())
                                    .map(V1ObjectMeta::getCreationTimestamp).orElse(null)))
                            .labels(Optional.ofNullable(ns.getMetadata()).map(V1ObjectMeta::getLabels).orElse(null))
                            .build())
                    .collect(Collectors.toList());
        } catch (ApiException e) {
            log.error("Failed to list namespaces: {} {}", e.getCode(), e.getResponseBody());
            throw new RuntimeException("Kubernetes API error: " + e.getMessage(), e);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // METRICS (Metrics Server API)
    // ──────────────────────────────────────────────────────────────────────────

    private Map<String, NodeMetrics> fetchNodeMetrics() {
        try {
            GenericKubernetesApi<NodeMetrics, NodeMetricsList> metricsApi =
                    new GenericKubernetesApi<>(NodeMetrics.class, NodeMetricsList.class,
                            "metrics.k8s.io", "v1beta1", "nodes", apiClient);

            NodeMetricsList list = metricsApi.list().throwsApiException().getObject();
            return safeList(list.getItems()).stream()
                    .collect(Collectors.toMap(
                            m -> m.getMetadata().getName(),
                            m -> m,
                            (a, b) -> a));
        } catch (Exception e) {
            log.warn("Metrics Server not available or returned error: {}", e.getMessage());
            return Collections.emptyMap();
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // HELPERS
    // ──────────────────────────────────────────────────────────────────────────

    private String computePodStatus(V1Pod pod, List<V1ContainerStatus> containerStatuses) {
        // Check for CrashLoopBackOff
        for (V1ContainerStatus cs : containerStatuses) {
            if (cs.getState() != null && cs.getState().getWaiting() != null) {
                String reason = cs.getState().getWaiting().getReason();
                if (reason != null) return reason; // CrashLoopBackOff, ImagePullBackOff, etc.
            }
        }
        return Optional.ofNullable(pod.getStatus()).map(V1PodStatus::getPhase).orElse("Unknown");
    }

    private String formatAge(OffsetDateTime creationTime) {
        if (creationTime == null) return "unknown";
        Duration d = Duration.between(creationTime, OffsetDateTime.now());
        if (d.toDays() > 0)    return d.toDays() + "d";
        if (d.toHours() > 0)   return d.toHours() + "h";
        if (d.toMinutes() > 0) return d.toMinutes() + "m";
        return d.toSeconds() + "s";
    }

    private long parseMillicores(Quantity q) {
        try {
            String s = q.toSuffixedString();
            if (s.endsWith("m")) return Long.parseLong(s.replace("m", ""));
            return Long.parseLong(s) * 1000L;
        } catch (Exception e) { return 0L; }
    }

    private long parseBytes(Quantity q) {
        try { return q.getNumber().toBigInteger().longValue(); }
        catch (Exception e) { return 0L; }
    }

    private <T> List<T> safeList(List<T> list) {
        return list != null ? list : Collections.emptyList();
    }

    private <T> int safeSize(List<T> list) {
        return list != null ? list.size() : 0;
    }
}
