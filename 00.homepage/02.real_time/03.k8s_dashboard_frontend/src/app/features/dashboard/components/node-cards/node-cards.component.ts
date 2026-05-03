import { Component, Input } from '@angular/core';
import { NgClass, NgStyle } from '@angular/common';
import { NodeInfo } from '../../../../core/models/k8s.models';

@Component({
  selector: 'app-node-cards',
  standalone: true,
  imports: [NgClass, NgStyle],
  template: `
    <div class="node-grid">
      @for (node of nodes; track node.name; let i = $index) {
        <div class="node-card" [style.animation-delay]="(i * 0.15) + 's'">
          <div class="node-header">
            <span class="node-name">{{ node.name }}</span>
            <span class="node-role" [ngClass]="node.role === 'control-plane' ? 'control' : 'worker'">
              {{ node.role }}
            </span>
          </div>
          <div class="node-ip">{{ node.internalIp ?? '–' }} · {{ node.version ?? '–' }}</div>

          <div class="node-stat">
            <div class="stat-row">
              <span class="stat-label">CPU</span>
              <span class="bar-val">{{ node.cpuPercent != null ? node.cpuPercent + '%' : '–' }}</span>
            </div>
            <div class="bar-track">
              <div class="bar-fill cpu" [ngStyle]="{ width: (node.cpuPercent ?? 0) + '%' }"></div>
            </div>
          </div>

          <div class="node-stat">
            <div class="stat-row">
              <span class="stat-label">MEM</span>
              <span class="bar-val">{{ node.memPercent != null ? node.memPercent + '%' : '–' }}</span>
            </div>
            <div class="bar-track">
              <div class="bar-fill mem" [ngStyle]="{ width: (node.memPercent ?? 0) + '%' }"></div>
            </div>
          </div>

          <div class="node-meta">{{ node.architecture ?? '' }} · {{ node.containerRuntime?.split('/')[0] ?? '' }}</div>
        </div>
      }
      @if (!nodes.length) {
        <div class="loading-msg">connecting to cluster…</div>
      }
    </div>
  `,
  styles: [`
    .node-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(180px,1fr)); gap:12px; }
    .node-card {
      background:#030810; border:1px solid #0d1f3c; border-radius:4px; padding:16px;
      opacity:0; animation:fadeUp 0.6s ease forwards;
    }
    @keyframes fadeUp { from{opacity:0;transform:translateY(12px)} to{opacity:1;transform:translateY(0)} }
    .node-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:4px; }
    .node-name   { font-family:'Share Tech Mono',monospace; font-size:11px; color:#fff; }
    .node-role   { font-family:'Share Tech Mono',monospace; font-size:9px; padding:2px 6px; border-radius:2px; letter-spacing:0.1em; }
    .node-role.control { background:rgba(0,229,255,0.1); color:#00e5ff; border:1px solid rgba(0,229,255,0.2); }
    .node-role.worker  { background:rgba(0,255,135,0.1); color:#00ff87; border:1px solid rgba(0,255,135,0.2); }
    .node-ip     { font-family:'Share Tech Mono',monospace; font-size:9px; color:#3a5068; margin-bottom:12px; }
    .node-stat   { margin-bottom:10px; }
    .stat-row    { display:flex; justify-content:space-between; margin-bottom:4px; }
    .stat-label  { font-family:'Share Tech Mono',monospace; font-size:9px; color:#3a5068; letter-spacing:0.15em; }
    .bar-val     { font-family:'Share Tech Mono',monospace; font-size:9px; color:#b0c4de; }
    .bar-track   { height:3px; background:#0d1f3c; border-radius:2px; overflow:hidden; }
    .bar-fill    { height:100%; border-radius:2px; transition:width 1s ease; }
    .bar-fill.cpu { background:linear-gradient(90deg,#ff6d00,#ffd600); }
    .bar-fill.mem { background:linear-gradient(90deg,#00e5ff,#00ff87); }
    .node-meta   { font-family:'Share Tech Mono',monospace; font-size:9px; color:#3a5068; margin-top:4px; }
    .loading-msg { font-family:'Share Tech Mono',monospace; font-size:11px; color:#3a5068; padding:24px; }
  `],
})
export class NodeCardsComponent {
  @Input() nodes: NodeInfo[] = [];
}
