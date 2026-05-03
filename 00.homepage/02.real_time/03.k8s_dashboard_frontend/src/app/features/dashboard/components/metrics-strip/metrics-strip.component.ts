import { Component, Input, computed, signal } from '@angular/core';
import { NgClass } from '@angular/common';
import { ClusterSummary, NodeInfo } from '../../../../core/models/k8s.models';

@Component({
  selector: 'app-metrics-strip',
  standalone: true,
  imports: [NgClass],
  template: `
    <div class="metrics-strip">
      @for (m of metrics(); track m.label) {
        <div class="metric" [style.--accent-color]="m.color"
             [style.animation-delay]="m.delay">
          <div class="metric-label">{{ m.label }}</div>
          <div class="metric-value" [style.color]="m.color">{{ m.value }}</div>
          <div class="metric-sub">{{ m.sub }}</div>
        </div>
      }
    </div>
  `,
  styles: [`
    .metrics-strip {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 1px;
      background: #0d1f3c;
      border-top: 1px solid #0d1f3c;
      border-bottom: 1px solid #0d1f3c;
      margin-top: 60px;
    }
    .metric {
      background: #080f1e;
      padding: 20px 24px;
      position: relative;
      overflow: hidden;
      opacity: 0;
      animation: fadeUp 0.6s ease forwards;
      &::before {
        content: ''; position: absolute; top: 0; left: 0; right: 0;
        height: 2px; background: var(--accent-color, #00e5ff);
      }
    }
    .metric-label { font-family: 'Share Tech Mono', monospace; font-size: 9px; color: #3a5068; letter-spacing: 0.25em; text-transform: uppercase; margin-bottom: 10px; }
    .metric-value { font-family: 'Barlow Condensed', sans-serif; font-size: 36px; font-weight: 900; line-height: 1; }
    .metric-sub   { font-family: 'Share Tech Mono', monospace; font-size: 10px; color: #3a5068; margin-top: 8px; }
    @keyframes fadeUp { from { opacity:0; transform:translateY(20px); } to { opacity:1; transform:translateY(0); } }
    @media (max-width: 600px) { .metrics-strip { grid-template-columns: repeat(2, 1fr); } }
  `],
})
export class MetricsStripComponent {
  @Input() summary: ClusterSummary | null = null;
  @Input() nodes: NodeInfo[] = [];

  metrics() {
    const s = this.summary;
    const avgCpu = this.avg(this.nodes.map(n => n.cpuPercent));
    const avgMem = this.avg(this.nodes.map(n => n.memPercent));
    return [
      { label: 'nodes',    value: s ? `${s.readyNodes}/${s.totalNodes}` : '–/–', sub: 'ready / total',  color: '#00e5ff', delay: '0.2s' },
      { label: 'pods',     value: s ? `${s.runningPods}/${s.totalPods}` : '–/–', sub: 'running / total', color: '#00ff87', delay: '0.35s' },
      { label: 'avg cpu',  value: avgCpu !== null ? `${avgCpu}%` : '–',           sub: 'across all nodes', color: '#ff6d00', delay: '0.5s' },
      { label: 'avg mem',  value: avgMem !== null ? `${avgMem}%` : '–',           sub: 'across all nodes', color: '#ffd600', delay: '0.65s' },
    ];
  }

  private avg(vals: (number | undefined)[]): number | null {
    const defined = vals.filter((v): v is number => v !== undefined && v !== null);
    if (!defined.length) return null;
    return Math.round(defined.reduce((a, b) => a + b, 0) / defined.length);
  }
}
