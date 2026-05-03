import { Component, Input } from '@angular/core';
import { NgClass } from '@angular/common';
import { K8sIngress } from '../../../../core/models/k8s.models';

@Component({
  selector: 'app-ingress-table',
  standalone: true,
  imports: [NgClass],
  template: `
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>NAME</th><th>NAMESPACE</th><th>CLASS</th>
            <th>HOSTS</th><th>ADDRESS</th><th>TLS</th><th>AGE</th>
          </tr>
        </thead>
        <tbody>
          @for (ing of ingresses; track ing.name) {
            <tr>
              <td class="name">{{ ing.name }}</td>
              <td class="dim">{{ ing.namespace }}</td>
              <td class="dim">{{ ing.ingressClass ?? 'nginx' }}</td>
              <td class="hosts">{{ hosts(ing) }}</td>
              <td class="dim">{{ ing.addresses?.[0] ?? '–' }}</td>
              <td [ngClass]="ing.tls ? 'tls-yes' : 'tls-no'">{{ ing.tls ? '✓ TLS' : '–' }}</td>
              <td class="dim">{{ ing.age }}</td>
            </tr>
          }
          @if (!ingresses.length) {
            <tr><td colspan="7" class="empty">no ingresses found</td></tr>
          }
        </tbody>
      </table>
    </div>
  `,
  styles: [`
    .table-wrap { overflow-x:auto; }
    table { width:100%; border-collapse:collapse; font-family:'Share Tech Mono',monospace; font-size:11px; }
    th { color:#3a5068; font-size:9px; letter-spacing:0.2em; text-align:left; padding:8px 12px; border-bottom:1px solid #0d1f3c; }
    td { padding:8px 12px; border-bottom:1px solid rgba(13,31,60,0.5); color:#b0c4de; }
    tr:hover td { background:rgba(0,229,255,0.03); }
    .name    { color:#fff; }
    .dim     { color:#3a5068; }
    .hosts   { color:#00b8d9; font-size:10px; }
    .tls-yes { color:#00ff87; font-size:10px; }
    .tls-no  { color:#3a5068; font-size:10px; }
    .empty   { color:#3a5068; text-align:center; padding:24px; }
  `],
})
export class IngressTableComponent {
  @Input() ingresses: K8sIngress[] = [];

  hosts(ing: K8sIngress): string {
    return (ing.rules ?? []).map(r => r.host ?? '*').join(', ') || '–';
  }
}
