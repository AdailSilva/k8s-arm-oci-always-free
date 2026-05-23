// ─────────────────────────────────────────────────────────────
// Models — mirror the Spring Boot DTOs
// ─────────────────────────────────────────────────────────────

export interface ClusterSummary {
  totalNodes: number;
  readyNodes: number;
  totalPods: number;
  runningPods: number;
  totalServices: number;
  totalIngresses: number;
  totalNamespaces: number;
  kubernetesVersion?: string;
}

export interface NodeInfo {
  name: string;
  status: 'Ready' | 'NotReady' | string;
  role: 'control-plane' | 'worker' | string;
  version?: string;
  internalIp?: string;
  os?: string;
  architecture?: string;
  containerRuntime?: string;
  age?: string;
  cpuCapacityMillicores?: number;
  memCapacityBytes?: number;
  cpuUsageMillicores?: number;
  memUsageBytes?: number;
  cpuPercent?: number;
  memPercent?: number;
  diskPercent?: number;
}

export interface Pod {
  name: string;
  namespace: string;
  nodeName?: string;
  status: string;   // Running / Pending / Failed / CrashLoopBackOff / ...
  phase?: string;
  ready: number;
  total: number;
  restarts: number;
  age?: string;
  image?: string;
  images?: string[];
  podIp?: string;
}

export interface ServicePort {
  name?: string;
  port?: number;
  targetPort?: number;
  nodePort?: number;
  protocol?: string;
}

export interface K8sService {
  name: string;
  namespace: string;
  type: string;   // ClusterIP / NodePort / LoadBalancer / ExternalName
  clusterIp?: string;
  externalIps?: string[];
  ports?: ServicePort[];
  age?: string;
  selector?: Record<string, string>;
}

export interface IngressPath {
  path?: string;
  pathType?: string;
  service?: string;
  servicePort?: number;
}

export interface IngressRule {
  host?: string;
  paths?: IngressPath[];
}

export interface K8sIngress {
  name: string;
  namespace: string;
  ingressClass?: string;
  rules?: IngressRule[];
  addresses?: string[];
  tls: boolean;
  age?: string;
}

export interface K8sNamespace {
  name: string;
  status: string;
  age?: string;
  labels?: Record<string, string>;
}
