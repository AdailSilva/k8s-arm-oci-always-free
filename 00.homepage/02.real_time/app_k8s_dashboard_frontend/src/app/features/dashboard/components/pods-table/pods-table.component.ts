import { Component, Input } from '@angular/core';
import { NgClass } from '@angular/common';
import { Pod } from '../../../../core/models/k8s.models';

@Component({
  selector: 'app-pods-table',
  standalone: true,
  imports: [NgClass],
  template: `
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>NAME</th>
            <th>NAMESPACE</th>
            <th>IMAGE</th>
            <th>STATUS</th>
            <th>READY</th>
            <th>RESTARTS</th>
            <th>AGE</th>
            <th>NODE</th>
          </tr>
        </thead>
        <tbody>
          @for (pod of pods; track pod.name) {
            <tr>
              <td class="pod-name">{{ pod.name }}</td>
              <td class="dim">{{ pod.namespace }}</td>
              <td class="dim small">{{ pod.image }}</td>
              <td><span class="pill" [ngClass]="statusClass(pod.status)">{{ pod.status }}</span></td>
              <td class="dim">{{ pod.ready }}/{{ pod.total }}</td>
              <td class="dim" [ngClass]="pod.restarts > 0 ? 'warn' : ''">{{ pod.restarts }}</td>
              <td class="dim">{{ pod.age }}</td>
              <td class="dim small">{{ pod.nodeName }}</td>
            </tr>
          }
          @if (!pods.length) {
            <tr><td colspan="8" class="empty">no pods found</td></tr>
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
    .pod-name { color:#fff; max-width:240px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
    .dim      { color:#3a5068; }
    .small    { font-size:10px; max-width:160px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
    .warn     { color:#ff6d00; }
    .empty    { color:#3a5068; text-align:center; padding:24px; }
    .pill { display:inline-block; padding:2px 8px; border-radius:2px; font-size:9px; letter-spacing:0.1em; }
    .pill.running   { background:rgba(0,255,135,0.1); color:#00ff87; border:1px solid rgba(0,255,135,0.2); }
    .pill.pending   { background:rgba(255,214,0,0.1); color:#ffd600; border:1px solid rgba(255,214,0,0.2); }
    .pill.failed,
    .pill.crashloopbackoff,
    .pill.error     { background:rgba(255,23,68,0.1);  color:#ff1744; border:1px solid rgba(255,23,68,0.2); }
    .pill.succeeded { background:rgba(0,229,255,0.1);  color:#00e5ff; border:1px solid rgba(0,229,255,0.2); }
  `],
})
export class PodsTableComponent {
  @Input() pods: Pod[] = [];

  statusClass(status: string): string {
    return status.toLowerCase().replace(/\s/g, '');
  }
}
