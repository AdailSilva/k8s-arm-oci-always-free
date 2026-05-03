import { Component, OnInit, OnDestroy, inject, signal, computed } from '@angular/core';
import { AsyncPipe, NgClass, NgFor, NgIf }     from '@angular/common';
import { FormsModule }                          from '@angular/forms';
import { Subject, takeUntil }                   from 'rxjs';
import { KubernetesService }                    from '../../../core/services/kubernetes.service';
import { ClusterCanvasComponent }               from '../components/cluster-canvas/cluster-canvas.component';
import { TerminalComponent }                    from '../components/terminal/terminal.component';
import { NodeCardsComponent }                   from '../components/node-cards/node-cards.component';
import { PodsTableComponent }                   from '../components/pods-table/pods-table.component';
import { MetricsStripComponent }                from '../components/metrics-strip/metrics-strip.component';
import { IngressTableComponent }                from '../components/ingress-table/ingress-table.component';
import { ServicesTableComponent }               from '../components/services-table/services-table.component';
import { ClusterSummary, K8sNamespace, NodeInfo, Pod, K8sService, K8sIngress } from '../../../core/models/k8s.models';

@Component({
  selector: 'app-dashboard-page',
  standalone: true,
  imports: [
    AsyncPipe, NgClass, NgFor, NgIf, FormsModule,
    ClusterCanvasComponent, TerminalComponent, NodeCardsComponent,
    PodsTableComponent, MetricsStripComponent, IngressTableComponent,
    ServicesTableComponent,
  ],
  templateUrl: './dashboard.page.html',
  styleUrls: ['./dashboard.page.scss'],
})
export class DashboardPage implements OnInit, OnDestroy {

  private readonly k8s     = inject(KubernetesService);
  private readonly destroy$ = new Subject<void>();

  // ── State signals ──────────────────────────────────────────────────────
  summary    = signal<ClusterSummary | null>(null);
  nodes      = signal<NodeInfo[]>([]);
  pods       = signal<Pod[]>([]);
  services   = signal<K8sService[]>([]);
  ingresses  = signal<K8sIngress[]>([]);
  namespaces = signal<K8sNamespace[]>([]);
  selectedNs = signal<string>('');
  clock      = signal<string>('');
  loading    = signal(true);
  error      = signal<string | null>(null);

  // Derived
  namespaceNames = computed(() =>
    ['', ...this.namespaces().map(n => n.name)]
  );

  ngOnInit() {
    this.startClock();
    this.subscribeData();
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  onNamespaceChange(ns: string) {
    this.selectedNs.set(ns);
    this.subscribeFiltered(ns);
  }

  private startClock() {
    const tick = () => {
      const now = new Date();
      this.clock.set(now.toISOString().replace('T', ' ').substring(0, 19) + ' UTC');
    };
    tick();
    setInterval(tick, 1000);
  }

  private subscribeData() {
    this.k8s.summary$.pipe(takeUntil(this.destroy$)).subscribe({
      next:  s => { this.summary.set(s); this.loading.set(false); },
      error: e => { this.error.set(e.message); this.loading.set(false); },
    });

    this.k8s.nodes$.pipe(takeUntil(this.destroy$)).subscribe({
      next: n => this.nodes.set(n),
    });

    this.k8s.namespaces$.pipe(takeUntil(this.destroy$)).subscribe({
      next: ns => this.namespaces.set(ns),
    });

    this.subscribeFiltered('');
  }

  private subscribeFiltered(ns: string) {
    this.k8s.pods$(ns || undefined).pipe(takeUntil(this.destroy$)).subscribe({
      next: p => this.pods.set(p),
    });
    this.k8s.services$(ns || undefined).pipe(takeUntil(this.destroy$)).subscribe({
      next: s => this.services.set(s),
    });
    this.k8s.ingresses$(ns || undefined).pipe(takeUntil(this.destroy$)).subscribe({
      next: i => this.ingresses.set(i),
    });
  }
}
