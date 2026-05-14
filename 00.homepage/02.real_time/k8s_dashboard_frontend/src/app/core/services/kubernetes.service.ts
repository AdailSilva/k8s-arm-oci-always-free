import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, timer, switchMap, shareReplay, startWith } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  ClusterSummary, NodeInfo, Pod,
  K8sService, K8sIngress, K8sNamespace
} from '../models/k8s.models';

@Injectable({ providedIn: 'root' })
export class KubernetesService {

  private readonly http = inject(HttpClient);
  private readonly base = environment.apiBaseUrl;
  private readonly interval = environment.refreshIntervalMs;

  // ── One-shot calls ──────────────────────────────────────────────────────

  getSummary(): Observable<ClusterSummary> {
    return this.http.get<ClusterSummary>(`${this.base}/summary`);
  }

  getNodes(): Observable<NodeInfo[]> {
    return this.http.get<NodeInfo[]>(`${this.base}/nodes`);
  }

  getPods(namespace?: string): Observable<Pod[]> {
    const params = namespace ? new HttpParams().set('namespace', namespace) : undefined;
    return this.http.get<Pod[]>(`${this.base}/pods`, { params });
  }

  getServices(namespace?: string): Observable<K8sService[]> {
    const params = namespace ? new HttpParams().set('namespace', namespace) : undefined;
    return this.http.get<K8sService[]>(`${this.base}/services`, { params });
  }

  getIngresses(namespace?: string): Observable<K8sIngress[]> {
    const params = namespace ? new HttpParams().set('namespace', namespace) : undefined;
    return this.http.get<K8sIngress[]>(`${this.base}/ingresses`, { params });
  }

  getNamespaces(): Observable<K8sNamespace[]> {
    return this.http.get<K8sNamespace[]>(`${this.base}/namespaces`);
  }

  // ── Auto-polling streams (refresh every N seconds) ──────────────────────

  readonly nodes$ = timer(0, this.interval).pipe(
    switchMap(() => this.getNodes()),
    shareReplay(1)
  );

  readonly summary$ = timer(0, this.interval).pipe(
    switchMap(() => this.getSummary()),
    shareReplay(1)
  );

  pods$(namespace?: string) {
    return timer(0, this.interval).pipe(
      switchMap(() => this.getPods(namespace)),
      shareReplay(1)
    );
  }

  services$(namespace?: string) {
    return timer(0, this.interval).pipe(
      switchMap(() => this.getServices(namespace)),
      shareReplay(1)
    );
  }

  ingresses$(namespace?: string) {
    return timer(0, this.interval).pipe(
      switchMap(() => this.getIngresses(namespace)),
      shareReplay(1)
    );
  }

  readonly namespaces$ = timer(0, this.interval).pipe(
    switchMap(() => this.getNamespaces()),
    shareReplay(1)
  );
}
