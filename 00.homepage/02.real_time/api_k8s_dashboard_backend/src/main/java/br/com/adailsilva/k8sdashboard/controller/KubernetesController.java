package br.com.adailsilva.k8sdashboard.controller;

import br.com.adailsilva.k8sdashboard.dto.*;
import br.com.adailsilva.k8sdashboard.service.KubernetesService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST API for the Kubernetes Dashboard.
 *
 * Base path: /api/k8s
 *
 * Endpoints:
 *   GET /api/k8s/summary                   → cluster overview counts
 *   GET /api/k8s/nodes                     → all nodes with metrics
 *   GET /api/k8s/pods?namespace=<ns>       → pods (all or filtered by namespace)
 *   GET /api/k8s/services?namespace=<ns>   → services
 *   GET /api/k8s/ingresses?namespace=<ns>  → ingresses
 *   GET /api/k8s/namespaces                → namespaces
 */
@Slf4j
@RestController
@RequestMapping("/api/k8s")
@RequiredArgsConstructor
public class KubernetesController {

    private final KubernetesService k8sService;

    // ── Summary ──────────────────────────────────────────────────────────────

    @GetMapping("/summary")
    public ResponseEntity<ClusterSummaryDto> getSummary() {
        log.debug("GET /api/k8s/summary");
        return ResponseEntity.ok(k8sService.getClusterSummary());
    }

    // ── Nodes ────────────────────────────────────────────────────────────────

    @GetMapping("/nodes")
    public ResponseEntity<List<NodeDto>> getNodes() {
        log.debug("GET /api/k8s/nodes");
        return ResponseEntity.ok(k8sService.getNodes());
    }

    // ── Pods ─────────────────────────────────────────────────────────────────

    @GetMapping("/pods")
    public ResponseEntity<List<PodDto>> getPods(
            @RequestParam(required = false) String namespace) {
        log.debug("GET /api/k8s/pods namespace={}", namespace);
        return ResponseEntity.ok(k8sService.getPods(namespace));
    }

    // ── Services ─────────────────────────────────────────────────────────────

    @GetMapping("/services")
    public ResponseEntity<List<ServiceDto>> getServices(
            @RequestParam(required = false) String namespace) {
        log.debug("GET /api/k8s/services namespace={}", namespace);
        return ResponseEntity.ok(k8sService.getServices(namespace));
    }

    // ── Ingresses ────────────────────────────────────────────────────────────

    @GetMapping("/ingresses")
    public ResponseEntity<List<IngressDto>> getIngresses(
            @RequestParam(required = false) String namespace) {
        log.debug("GET /api/k8s/ingresses namespace={}", namespace);
        return ResponseEntity.ok(k8sService.getIngresses(namespace));
    }

    // ── Namespaces ───────────────────────────────────────────────────────────

    @GetMapping("/namespaces")
    public ResponseEntity<List<NamespaceDto>> getNamespaces() {
        log.debug("GET /api/k8s/namespaces");
        return ResponseEntity.ok(k8sService.getNamespaces());
    }

    // ── Health (for readiness probe) ─────────────────────────────────────────

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("OK");
    }
}
