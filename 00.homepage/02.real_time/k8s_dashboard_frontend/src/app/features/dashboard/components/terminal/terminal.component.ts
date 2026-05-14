import {
  Component, Input, OnChanges, AfterViewInit,
  ElementRef, ViewChild, SimpleChanges
} from '@angular/core';
import { NodeInfo, Pod, K8sIngress } from '../../../../core/models/k8s.models';

interface TermLine { type: 'cmd' | 'out' | 'blank'; text?: string; }

@Component({
  selector: 'app-terminal',
  standalone: true,
  template: `
    <div class="terminal">
      <div class="term-header">
        <span class="term-dot red"></span>
        <span class="term-dot yellow"></span>
        <span class="term-dot green"></span>
        <span class="term-title">bash — kubectl</span>
      </div>
      <div class="term-body" #termBody></div>
    </div>
  `,
  styles: [`
    .terminal { background:#030810; border:1px solid #0d1f3c; border-radius:6px; overflow:hidden; }
    .term-header { display:flex; align-items:center; gap:6px; padding:10px 14px; background:#060c18; border-bottom:1px solid #0d1f3c; }
    .term-dot { width:10px; height:10px; border-radius:50%; }
    .term-dot.red    { background:#ff5f57; }
    .term-dot.yellow { background:#febc2e; }
    .term-dot.green  { background:#28c840; }
    .term-title { font-family:'Share Tech Mono',monospace; font-size:10px; color:#3a5068; margin-left:8px; letter-spacing:0.1em; }
    .term-body { padding:16px; min-height:220px; font-family:'Share Tech Mono',monospace; font-size:11px; line-height:1.7; color:#b0c4de; overflow:auto; max-height:280px; }
    :host ::ng-deep {
      .t-prompt { color:#00e5ff; margin-right:8px; }
      .t-cmd    { color:#00ff87; }
      .t-out    { color:#b0c4de; display:block; padding-left:18px; }
      .t-hi     { color:#ffd600; }
      .t-ok     { color:#00ff87; }
      .t-err    { color:#ff1744; }
      .t-blank  { display:block; height:8px; }
      .t-line   { display:flex; align-items:baseline; }
      .cursor   { display:inline-block; width:8px; height:13px; background:#00e5ff; animation:blink-cursor 1s step-end infinite; vertical-align:text-bottom; margin-left:2px; }
      @keyframes blink-cursor { 0%,100%{opacity:1} 50%{opacity:0} }
    }
  `],
})
export class TerminalComponent implements OnChanges, AfterViewInit {

  @Input() nodes: NodeInfo[]    = [];
  @Input() pods: Pod[]          = [];
  @Input() ingresses: K8sIngress[] = [];

  @ViewChild('termBody') termBodyRef!: ElementRef<HTMLDivElement>;

  private started = false;
  private pendingUpdate = false;

  ngAfterViewInit() {
    if (!this.started && (this.nodes.length || this.pods.length)) {
      this.started = true;
      this.runTypewriter();
    }
  }

  ngOnChanges(ch: SimpleChanges) {
    if (this.termBodyRef && !this.started && (this.nodes.length || this.pods.length)) {
      this.started = true;
      this.runTypewriter();
    } else if (this.started) {
      this.pendingUpdate = true;
    }
  }

  private buildLines(): TermLine[] {
    const lines: TermLine[] = [];

    // kubectl get nodes
    lines.push({ type: 'cmd', text: 'kubectl get nodes -o wide' });
    lines.push({ type: 'out', text: `<span class="t-hi">NAME             STATUS   ROLES           AGE     VERSION</span>` });
    this.nodes.forEach(n => {
      const status = n.status === 'Ready'
        ? `<span class="t-ok">Ready</span>`
        : `<span class="t-err">NotReady</span>`;
      lines.push({ type: 'out', text: `<span class="t-ok">${n.name.padEnd(16)}</span> ${status.padEnd(8)} ${(n.role ?? 'worker').padEnd(15)} ${(n.age ?? '-').padEnd(7)} ${n.version ?? '-'}` });
    });
    lines.push({ type: 'blank' });

    // kubectl get pods
    const ns = this.pods[0]?.namespace ?? 'oci-devops';
    lines.push({ type: 'cmd', text: `kubectl get pods -n ${ns}` });
    lines.push({ type: 'out', text: `<span class="t-hi">NAME${' '.repeat(36)}READY   STATUS    RESTARTS</span>` });
    this.pods.slice(0, 8).forEach(p => {
      const statusClass = p.status === 'Running' ? 't-ok' : 't-err';
      const name = p.name.length > 38 ? p.name.substring(0, 35) + '...' : p.name;
      lines.push({ type: 'out', text: `<span class="${statusClass}">${name.padEnd(40)}</span>${p.ready}/${p.total}     ${p.status.padEnd(9)} ${p.restarts}` });
    });
    lines.push({ type: 'blank' });

    // kubectl get ingress
    if (this.ingresses.length) {
      lines.push({ type: 'cmd', text: 'kubectl get ingress -A' });
      lines.push({ type: 'out', text: `<span class="t-hi">NAMESPACE    NAME              HOSTS                          ADDRESS    TLS</span>` });
      this.ingresses.slice(0, 4).forEach(i => {
        const host = i.rules?.[0]?.host ?? '-';
        const addr = i.addresses?.[0] ?? '-';
        lines.push({ type: 'out', text: `<span class="t-ok">${(i.namespace ?? '').padEnd(12)} ${i.name.padEnd(17)}</span> ${host.padEnd(30)} ${addr.padEnd(10)} ${i.tls ? 'True' : 'False'}` });
      });
    }

    return lines;
  }

  private runTypewriter() {
    const body  = this.termBodyRef.nativeElement;
    const lines = this.buildLines();
    body.innerHTML = '';
    let lineIdx = 0;
    let charIdx = 0;
    let isTyping = false;

    const typeNext = () => {
      if (lineIdx >= lines.length) {
        const cur = document.createElement('span');
        cur.className = 'cursor';
        body.appendChild(cur);

        // Re-run with fresh data after interval
        setTimeout(() => {
          this.started = false;
          this.ngAfterViewInit();
        }, 15_000);
        return;
      }

      const line = lines[lineIdx];

      if (line.type === 'blank') {
        const el = document.createElement('span');
        el.className = 't-blank';
        body.appendChild(el);
        lineIdx++; charIdx = 0;
        setTimeout(typeNext, 80);
        return;
      }

      if (line.type === 'out') {
        const el = document.createElement('div');
        el.className = 't-out';
        el.innerHTML = line.text ?? '';
        body.appendChild(el);
        body.scrollTop = body.scrollHeight;
        lineIdx++; charIdx = 0;
        setTimeout(typeNext, 40);
        return;
      }

      if (line.type === 'cmd') {
        if (!isTyping) {
          isTyping = true;
          const el = document.createElement('div');
          el.className = 't-line';
          const prompt = document.createElement('span');
          prompt.className = 't-prompt'; prompt.textContent = '❯';
          const cmd = document.createElement('span');
          cmd.className = 't-cmd'; cmd.textContent = '';
          el.appendChild(prompt); el.appendChild(cmd);
          body.appendChild(el);
        }
        const cmdSpan = (body.lastChild as HTMLElement).querySelector('.t-cmd')!;
        if (charIdx < (line.text ?? '').length) {
          cmdSpan.textContent += (line.text ?? '')[charIdx];
          charIdx++;
          body.scrollTop = body.scrollHeight;
          setTimeout(typeNext, 35 + Math.random() * 40);
        } else {
          isTyping = false;
          lineIdx++; charIdx = 0;
          setTimeout(typeNext, 200);
        }
      }
    };

    setTimeout(typeNext, 600);
  }
}
