import { Component, Input } from '@angular/core';
import { K8sService } from '../../../../core/models/k8s.models';

@Component({
  selector: 'app-services-table',
  standalone: true,
  template: `
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>NAME</th><th>NAMESPACE</th><th>TYPE</th>
            <th>CLUSTER-IP</th><th>PORTS</th><th>AGE</th>
          </tr>
        </thead>
        <tbody>
          @for (svc of services; track svc.name) {
            <tr>
              <td class="name">{{ svc.name }}</td>
              <td class="dim">{{ svc.namespace }}</td>
              <td><span class="pill type-{{ svc.type?.toLowerCase() }}">{{ svc.type }}</span></td>
              <td class="dim">{{ svc.clusterIp }}</td>
              <td class="dim small">{{ formatPorts(svc) }}</td>
              <td class="dim">{{ svc.age }}</td>
            </tr>
          }
          @if (!services.length) {
            <tr><td colspan="6" class="empty">no services found</td></tr>
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
    .name  { color:#fff; }
    .dim   { color:#3a5068; }
    .small { font-size:10px; }
    .empty { color:#3a5068; text-align:center; padding:24px; }
    .pill  { display:inline-block; padding:2px 8px; border-radius:2px; font-size:9px; }
    .pill.type-clusterip    { background:rgba(0,229,255,0.08); color:#00e5ff; border:1px solid rgba(0,229,255,0.15); }
    .pill.type-nodeport     { background:rgba(255,109,0,0.08); color:#ff6d00; border:1px solid rgba(255,109,0,0.15); }
    .pill.type-loadbalancer { background:rgba(0,255,135,0.08); color:#00ff87; border:1px solid rgba(0,255,135,0.15); }
  `],
})
export class ServicesTableComponent {
  @Input() services: K8sService[] = [];

  formatPorts(svc: K8sService): string {
    return (svc.ports ?? [])
      .map(p => p.nodePort ? `${p.port}:${p.nodePort}/${p.protocol}` : `${p.port}/${p.protocol}`)
      .join(', ');
  }
}
