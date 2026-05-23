import {
  Component, Input, OnChanges, AfterViewInit, OnDestroy,
  ElementRef, ViewChild, SimpleChanges, NgZone
} from '@angular/core';
import { NodeInfo } from '../../../../core/models/k8s.models';

interface DrawNode {
  label: string;
  role:  string;
  pods:  number;
  color: string;
  xRatio: number;
  r:  number;
  px: number;
  py: number;
}

interface Satellite {
  label:     string;
  color:     string;
  dist:      number;
  baseAngle: number;
  dir:       number;
  px:        number;
  py:        number;
}

interface Packet {
  from:     DrawNode;
  to:       DrawNode;
  progress: number;
  speed:    number;
  color:    string;
}

@Component({
  selector:   'app-cluster-canvas',
  standalone: true,
  template: `<canvas #canvas style="display:block;width:100%;height:300px"></canvas>`,
})
export class ClusterCanvasComponent implements AfterViewInit, OnChanges, OnDestroy {

  @Input() nodes: NodeInfo[] = [];
  @ViewChild('canvas') canvasRef!: ElementRef<HTMLCanvasElement>;

  private ctx!: CanvasRenderingContext2D;
  private animFrame  = 0;
  private packets:    Packet[]    = [];
  private drawNodes:  DrawNode[]  = [];
  private satellites: Satellite[] = [];
  private t   = 0;
  private DPR = Math.min(window.devicePixelRatio || 1, 2);
  private W   = 0;
  private H   = 550;
  private resizeObs!: ResizeObserver;

  constructor(private zone: NgZone) {}

  ngAfterViewInit(): void {
    const canvas = this.canvasRef.nativeElement;
    this.ctx = canvas.getContext('2d')!;
    this.resizeObs = new ResizeObserver(() => this.onResize());
    this.resizeObs.observe(canvas.parentElement!);
    this.onResize();
    this.rebuildNodes();
    this.zone.runOutsideAngular(() => this.tick());
  }

  ngOnChanges(ch: SimpleChanges): void {
    if (ch['nodes'] && this.ctx) this.rebuildNodes();
  }

  ngOnDestroy(): void {
    cancelAnimationFrame(this.animFrame);
    this.resizeObs?.disconnect();
  }

  private onResize(): void {
    const canvas = this.canvasRef.nativeElement;
    this.W = canvas.parentElement!.clientWidth || 700;
    canvas.width        = this.W * this.DPR;
    canvas.height       = this.H * this.DPR;
    canvas.style.width  = this.W + 'px';
    canvas.style.height = this.H + 'px';
    // Reseta a matrix antes de escalar — evita escala acumulativa a cada resize
    this.ctx.setTransform(this.DPR, 0, 0, this.DPR, 0, 0);
    this.rebuildNodes();
  }

  private rebuildNodes(): void {
    if (!this.ctx) return;
    const W = this.W || 700;
    const H = this.H;
    const cx = W / 2;
    const cy = H * 0.44;

    if (!this.nodes.length) {
      this.drawNodes = [
        { label: 'master-01', role: 'control-plane', pods: 4, color: '#00e5ff', xRatio: 0.5, r: 22, px: cx,       py: cy       },
        { label: 'worker-01', role: 'worker',         pods: 3, color: '#00ff87', xRatio: 0.2, r: 16, px: cx - 140, py: cy + 85  },
        { label: 'worker-02', role: 'worker',         pods: 2, color: '#00ff87', xRatio: 0.8, r: 16, px: cx + 140, py: cy + 85  },
        { label: 'worker-03', role: 'worker',         pods: 3, color: '#00ff87', xRatio: 0.5, r: 16, px: cx,       py: cy + 120 },
      ];
    } else {
      const cp      = this.nodes.find(n => n.role === 'control-plane');
      const workers = this.nodes.filter(n => n.role === 'worker');
      const result: DrawNode[] = [];

      if (cp) {
        result.push({
          label: cp.name, role: 'control-plane',
          pods:  Math.max(2, Math.round((cp.cpuPercent ?? 40) / 20)),
          color: '#00e5ff', xRatio: 0.5, r: 22, px: cx, py: cy,
        });
      }

      workers.forEach((w, i) => {
        const total = Math.max(workers.length, 1);
        const ang   = (i / total) * Math.PI * 2 - Math.PI / 2;
        const dist  = Math.min(W, H * 2) * 0.28;
        result.push({
          label:  w.name, role: 'worker',
          pods:   Math.max(1, Math.round((w.cpuPercent ?? 30) / 25)),
          color:  '#00ff87', xRatio: i / total, r: 16,
          px: cx + Math.cos(ang) * dist,
          py: cy + Math.sin(ang) * dist,
        });
      });

      this.drawNodes = result;
    }

    this.satellites = [
      { label: 'nginx',    color: '#ff6d00', dist: 85, baseAngle: -Math.PI / 3, dir:  1, px: 0, py: 0 },
      { label: 'cert-mgr', color: '#ffd600', dist: 85, baseAngle: 0,            dir: -1, px: 0, py: 0 },
      { label: 'kube-dns', color: '#b388ff', dist: 70, baseAngle:  Math.PI / 3, dir:  1, px: 0, py: 0 },
    ];
  }

  private tick = (): void => {
    this.draw();
    this.animFrame = requestAnimationFrame(this.tick);
  };

  private draw(): void {
    const ctx = this.ctx;
    if (!ctx || !this.W) return;

    this.t += 0.016;
    const W = this.W, H = this.H;
    ctx.clearRect(0, 0, W, H);

    // ── Arestas tracejadas animadas
    for (let i = 0; i < this.drawNodes.length; i++) {
      for (let j = i + 1; j < this.drawNodes.length; j++) {
        const a = this.drawNodes[i], b = this.drawNodes[j];
        const grad = ctx.createLinearGradient(a.px, a.py, b.px, b.py);
        grad.addColorStop(0, a.color + '40');
        grad.addColorStop(1, b.color + '40');
        ctx.strokeStyle    = grad;
        ctx.lineWidth      = 1;
        ctx.setLineDash([4, 8]);
        ctx.lineDashOffset = -(this.t * 20);
        ctx.beginPath();
        ctx.moveTo(a.px, a.py);
        ctx.lineTo(b.px, b.py);
        ctx.stroke();
      }
    }
    ctx.setLineDash([]);

    // ── Satélites orbitando o master
    const master = this.drawNodes.find(n => n.role === 'control-plane');
    if (master) {
      this.satellites.forEach(s => {
        const ang = s.baseAngle + this.t * 0.15 * s.dir;
        s.px = master.px + Math.cos(ang) * s.dist;
        s.py = master.py + Math.sin(ang) * s.dist;

        ctx.strokeStyle = s.color + '30';
        ctx.lineWidth   = 0.8;
        ctx.beginPath();
        ctx.moveTo(master.px, master.py);
        ctx.lineTo(s.px, s.py);
        ctx.stroke();

        ctx.fillStyle   = s.color + '18';
        ctx.strokeStyle = s.color + '60';
        ctx.lineWidth   = 1;
        ctx.beginPath();
        ctx.arc(s.px, s.py, 12, 0, Math.PI * 2);
        ctx.fill();
        ctx.stroke();

        ctx.fillStyle    = s.color;
        ctx.font         = "9px 'Share Tech Mono', monospace";
        ctx.textAlign    = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(s.label, s.px, s.py);
      });
    }

    // ── Pacotes de dados
    if (this.drawNodes.length >= 2 && Math.random() < 0.03) {
      const from = this.drawNodes[Math.floor(Math.random() * this.drawNodes.length)];
      const to   = this.drawNodes[Math.floor(Math.random() * this.drawNodes.length)];
      if (from !== to) {
        this.packets.push({ from, to, progress: 0, speed: 0.008 + Math.random() * 0.01, color: from.color });
      }
    }

    this.packets = this.packets.filter(p => {
      p.progress += p.speed;
      if (p.progress >= 1) return false;
      const x = p.from.px + (p.to.px - p.from.px) * p.progress;
      const y = p.from.py + (p.to.py - p.from.py) * p.progress;
      ctx.fillStyle   = p.color;
      ctx.shadowColor = p.color;
      ctx.shadowBlur  = 8;
      ctx.beginPath();
      ctx.arc(x, y, 3, 0, Math.PI * 2);
      ctx.fill();
      ctx.shadowBlur  = 0;
      return true;
    });

    // ── Nós
    this.drawNodes.forEach(n => {
      const pulse = 1 + 0.08 * Math.sin(this.t * 2 + n.xRatio * 10);

      const glow = ctx.createRadialGradient(n.px, n.py, n.r * 0.5, n.px, n.py, n.r * 2.5 * pulse);
      glow.addColorStop(0, n.color + '25');
      glow.addColorStop(1, 'transparent');
      ctx.fillStyle = glow;
      ctx.beginPath();
      ctx.arc(n.px, n.py, n.r * 2.5 * pulse, 0, Math.PI * 2);
      ctx.fill();

      ctx.fillStyle   = '#060c18';
      ctx.strokeStyle = n.color;
      ctx.lineWidth   = 2;
      ctx.shadowColor = n.color;
      ctx.shadowBlur  = 12;
      ctx.beginPath();
      ctx.arc(n.px, n.py, n.r * pulse, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      ctx.shadowBlur = 0;

      for (let p = 0; p < n.pods; p++) {
        const ang = (p / n.pods) * Math.PI * 2 + this.t;
        ctx.fillStyle = n.color + 'cc';
        ctx.beginPath();
        ctx.arc(
          n.px + Math.cos(ang) * n.r * 0.55,
          n.py + Math.sin(ang) * n.r * 0.55,
          2.5, 0, Math.PI * 2
        );
        ctx.fill();
      }

      ctx.fillStyle    = '#ffffff';
      ctx.font         = "bold 10px 'Share Tech Mono', monospace";
      ctx.textAlign    = 'center';
      ctx.textBaseline = 'top';
      ctx.fillText(n.label, n.px, n.py + n.r * pulse + 6);

      ctx.fillStyle = n.color + 'aa';
      ctx.font      = "9px 'Share Tech Mono', monospace";
      ctx.fillText(n.role, n.px, n.py + n.r * pulse + 18);
    });
  }
}
