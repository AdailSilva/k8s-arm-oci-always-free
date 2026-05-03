import {
  Component, Input, OnChanges, AfterViewInit,
  ElementRef, ViewChild, SimpleChanges, NgZone
} from '@angular/core';
import { NodeInfo } from '../../../../core/models/k8s.models';

interface DrawNode { label: string; role: string; pods: number; color: string; x: number; px: number; py: number; r: number; }
interface Worker    { label: string; color: string; dist: number; angle: number; px: number; py: number; }
interface Packet    { from: DrawNode; to: DrawNode; progress: number; speed: number; color: string; }

@Component({
  selector: 'app-cluster-canvas',
  standalone: true,
  template: `<canvas #canvas style="width:100%;height:260px;display:block"></canvas>`,
})
export class ClusterCanvasComponent implements AfterViewInit, OnChanges {

  @Input() nodes: NodeInfo[] = [];
  @ViewChild('canvas') canvasRef!: ElementRef<HTMLCanvasElement>;

  private animFrame = 0;
  private packets: Packet[] = [];
  private t = 0;

  constructor(private zone: NgZone) {}

  ngAfterViewInit() { this.startAnimation(); }

  ngOnChanges(ch: SimpleChanges) {
    if (ch['nodes'] && this.canvasRef) this.startAnimation();
  }

  private startAnimation() {
    cancelAnimationFrame(this.animFrame);
    this.zone.runOutsideAngular(() => this.draw());
  }

  private draw() {
    const canvas = this.canvasRef?.nativeElement;
    if (!canvas) return;
    const parent = canvas.parentElement!;
    canvas.width  = parent.clientWidth;
    canvas.height = 260;
    const ctx = canvas.getContext('2d')!;
    const W = canvas.width, H = canvas.height;

    this.t += 0.005;

    // Build drawable nodes from real data
    const drawNodes = this.buildDrawNodes(W, H);

    ctx.clearRect(0, 0, W, H);

    // Connections
    const master = drawNodes.find(n => n.role === 'control-plane');
    const workers = drawNodes.filter(n => n.role === 'worker');

    if (master) {
      workers.forEach(w => {
        ctx.strokeStyle = w.color + '30';
        ctx.lineWidth = 0.8;
        ctx.beginPath(); ctx.moveTo(master.px, master.py); ctx.lineTo(w.px, w.py); ctx.stroke();
      });
    }

    // Spawn & draw packets
    if (drawNodes.length >= 2 && Math.random() < 0.04) {
      const from = drawNodes[Math.floor(Math.random() * drawNodes.length)];
      let to = drawNodes[Math.floor(Math.random() * drawNodes.length)];
      if (from !== to) {
        this.packets.push({ from, to, progress: 0, speed: 0.008 + Math.random() * 0.01, color: from.color });
      }
    }

    this.packets = this.packets.filter(p => {
      p.progress += p.speed;
      if (p.progress >= 1) return false;
      const x = p.from.px + (p.to.px - p.from.px) * p.progress;
      const y = p.from.py + (p.to.py - p.from.py) * p.progress;
      ctx.fillStyle = p.color;
      ctx.shadowColor = p.color; ctx.shadowBlur = 8;
      ctx.beginPath(); ctx.arc(x, y, 3, 0, Math.PI * 2); ctx.fill();
      ctx.shadowBlur = 0;
      return true;
    });

    // Draw nodes
    drawNodes.forEach(n => {
      const pulse = 1 + 0.08 * Math.sin(this.t * 2 + n.x * 10);
      const grad = ctx.createRadialGradient(n.px, n.py, n.r * 0.5, n.px, n.py, n.r * 2.5 * pulse);
      grad.addColorStop(0, n.color + '25'); grad.addColorStop(1, 'transparent');
      ctx.fillStyle = grad;
      ctx.beginPath(); ctx.arc(n.px, n.py, n.r * 2.5 * pulse, 0, Math.PI * 2); ctx.fill();

      ctx.fillStyle = '#060c18'; ctx.strokeStyle = n.color;
      ctx.lineWidth = 2; ctx.shadowColor = n.color; ctx.shadowBlur = 12;
      ctx.beginPath(); ctx.arc(n.px, n.py, n.r * pulse, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
      ctx.shadowBlur = 0;

      for (let p = 0; p < n.pods; p++) {
        const ang = (p / n.pods) * Math.PI * 2 + this.t;
        ctx.fillStyle = n.color + 'cc';
        ctx.beginPath();
        ctx.arc(n.px + Math.cos(ang) * n.r * 0.55, n.py + Math.sin(ang) * n.r * 0.55, 2.5, 0, Math.PI * 2);
        ctx.fill();
      }

      ctx.fillStyle = '#fff'; ctx.font = `bold 10px 'Share Tech Mono', monospace`;
      ctx.textAlign = 'center'; ctx.textBaseline = 'top';
      ctx.fillText(n.label, n.px, n.py + n.r * pulse + 6);
      ctx.fillStyle = n.color + 'aa'; ctx.font = `9px 'Share Tech Mono', monospace`;
      ctx.fillText(n.role, n.px, n.py + n.r * pulse + 18);
    });

    this.animFrame = requestAnimationFrame(() => this.draw());
  }

  private buildDrawNodes(W: number, H: number): DrawNode[] {
    if (!this.nodes.length) return this.defaultNodes(W, H);

    const cp      = this.nodes.find(n => n.role === 'control-plane');
    const workers = this.nodes.filter(n => n.role === 'worker');
    const result: DrawNode[] = [];
    const cx = W / 2, cy = H / 2 - 20;

    if (cp) {
      result.push({
        label: cp.name, role: 'control-plane', pods: 3,
        color: '#00e5ff', x: 0.5, r: 28, px: cx, py: cy,
      });
    }

    workers.forEach((w, i) => {
      const total = workers.length;
      const ang   = ((i / total) * Math.PI * 2) - Math.PI / 2;
      const dist  = Math.min(W, H) * 0.32;
      result.push({
        label: w.name, role: 'worker',
        pods: Math.max(1, Math.round((w.cpuPercent ?? 30) / 25)),
        color: '#00ff87', x: i / total, r: 20,
        px: cx + Math.cos(ang) * dist,
        py: cy + Math.sin(ang) * dist,
      });
    });

    return result;
  }

  private defaultNodes(W: number, H: number): DrawNode[] {
    const cx = W / 2, cy = H / 2 - 20;
    return [
      { label: 'leader', role: 'control-plane', pods: 3, color: '#00e5ff', x: 0.5, r: 28, px: cx, py: cy },
      { label: 'worker-0', role: 'worker', pods: 2, color: '#00ff87', x: 0, r: 20, px: cx - 130, py: cy + 60 },
      { label: 'worker-1', role: 'worker', pods: 2, color: '#00ff87', x: 0.5, r: 20, px: cx, py: cy + 110 },
      { label: 'worker-2', role: 'worker', pods: 2, color: '#00ff87', x: 1, r: 20, px: cx + 130, py: cy + 60 },
    ];
  }
}
