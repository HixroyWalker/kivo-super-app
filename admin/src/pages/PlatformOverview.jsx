import React from 'react';
import {
  TrendingUp,
  Users,
  Store,
  ArrowUpRight,
  Landmark,
  Activity,
  CheckCircle2,
  AlertCircle,
} from 'lucide-react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
} from 'recharts';

const chartData = [
  { day: 'Mon', volume: 1450000, revenue: 29000, txCount: 840 },
  { day: 'Tue', volume: 1890000, revenue: 37800, txCount: 1120 },
  { day: 'Wed', volume: 2200000, revenue: 44000, txCount: 1350 },
  { day: 'Thu', volume: 1950000, revenue: 39000, txCount: 1210 },
  { day: 'Fri', volume: 3400000, revenue: 68000, txCount: 2450 },
  { day: 'Sat', volume: 4800000, revenue: 96000, txCount: 3890 },
  { day: 'Sun', volume: 2900000, revenue: 58000, txCount: 1980 },
];

const categoryData = [
  { category: 'P2P Transfers', count: 4500, amount: 6200000 },
  { category: 'Merchant QR Pay', count: 3200, amount: 8400000 },
  { category: 'Marketplace Orders', count: 1800, amount: 3900000 },
  { category: 'Lynk BOJ Top-Ups', count: 2100, amount: 4800000 },
];

const PlatformOverview = () => {
  return (
    <div>
      {/* Header */}
      <div style={{ marginBottom: '28px' }}>
        <h1 style={{ fontSize: '26px', fontWeight: 800, letterSpacing: '-0.5px', marginBottom: '6px' }}>
          Platform Financial Health & Metrics
        </h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
          Real-time transaction telemetry across the KIVO Super App network in Jamaica.
        </p>
      </div>

      {/* Metrics Row */}
      <div className="metrics-grid">
        <div className="card metric-card">
          <div className="metric-header">
            <span className="metric-title">24h Gross Volume</span>
            <div style={{ padding: '8px', borderRadius: '8px', backgroundColor: 'rgba(0, 230, 118, 0.1)', color: 'var(--emerald-primary)' }}>
              <TrendingUp size={18} />
            </div>
          </div>
          <div className="metric-value">JMD $19.59M</div>
          <div className="metric-change positive">
            <ArrowUpRight size={16} /> +18.4% vs last week
          </div>
        </div>

        <div className="card metric-card">
          <div className="metric-header">
            <span className="metric-title">Platform Fee Revenue</span>
            <div style={{ padding: '8px', borderRadius: '8px', backgroundColor: 'rgba(0, 229, 255, 0.1)', color: 'var(--cyan-accent)' }}>
              <Landmark size={18} />
            </div>
          </div>
          <div className="metric-value">JMD $371.8K</div>
          <div className="metric-change positive">
            <ArrowUpRight size={16} /> +12.1% net profit
          </div>
        </div>

        <div className="card metric-card">
          <div className="metric-header">
            <span className="metric-title">Active Merchants</span>
            <div style={{ padding: '8px', borderRadius: '8px', backgroundColor: 'rgba(255, 179, 0, 0.1)', color: 'var(--amber-warning)' }}>
              <Store size={18} />
            </div>
          </div>
          <div className="metric-value">1,428</div>
          <div className="metric-change positive">
            <ArrowUpRight size={16} /> +42 new this month
          </div>
        </div>

        <div className="card metric-card">
          <div className="metric-header">
            <span className="metric-title">Lynk Gateway Health</span>
            <div style={{ padding: '8px', borderRadius: '8px', backgroundColor: 'rgba(0, 230, 118, 0.1)', color: 'var(--emerald-primary)' }}>
              <Activity size={18} />
            </div>
          </div>
          <div className="metric-value" style={{ color: 'var(--emerald-primary)', fontSize: '24px' }}>99.98%</div>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <CheckCircle2 size={14} color="var(--emerald-primary)" /> BOJ Jam-Dex Node Active
          </div>
        </div>
      </div>

      {/* Charts Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px', marginBottom: '28px' }}>
        {/* Main Volume Chart */}
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <div>
              <h3 style={{ fontSize: '16px', fontWeight: 700 }}>Weekly Transaction Volume (JMD)</h3>
              <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Daily settled payment volume across all rails</p>
            </div>
            <span className="badge badge-emerald">Live Telemetry</span>
          </div>

          <div style={{ height: '280px', width: '100%' }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chartData}>
                <defs>
                  <linearGradient id="colorVolume" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#00E676" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="#00E676" stopOpacity={0.0} />
                  </linearGradient>
                </defs>
                <XAxis dataKey="day" stroke="#607D8B" fontSize={12} tickLine={false} />
                <YAxis stroke="#607D8B" fontSize={12} tickLine={false} tickFormatter={(val) => `$${(val / 1000000).toFixed(1)}M`} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#141D26', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px' }}
                  formatter={(val) => [`JMD $${Number(val).toLocaleString()}`, 'Volume']}
                />
                <Area type="monotone" dataKey="volume" stroke="#00E676" strokeWidth={3} fillOpacity={1} fill="url(#colorVolume)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Category Breakdown */}
        <div className="card">
          <div style={{ marginBottom: '20px' }}>
            <h3 style={{ fontSize: '16px', fontWeight: 700 }}>Rail Breakdown</h3>
            <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Volume by service category</p>
          </div>

          <div style={{ height: '280px', width: '100%' }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={categoryData} layout="vertical">
                <XAxis type="number" hide />
                <YAxis dataKey="category" type="category" stroke="#90A4AE" fontSize={11} width={110} tickLine={false} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#141D26', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px' }}
                  formatter={(val) => [`JMD $${Number(val).toLocaleString()}`, 'Volume']}
                />
                <Bar dataKey="amount" fill="#00E5FF" radius={[0, 6, 6, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Real-Time Settlement Queue */}
      <div className="card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <div>
            <h3 style={{ fontSize: '16px', fontWeight: 700 }}>Real-Time System Log & Audits</h3>
            <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Verified transactions and automated compliance checks</p>
          </div>
          <button className="btn btn-secondary" style={{ fontSize: '12px', padding: '6px 12px' }}>
            Export Audit Log
          </button>
        </div>

        <div className="table-container">
          <table className="admin-table">
            <thead>
              <tr>
                <th>Transaction ID</th>
                <th>Type</th>
                <th>Sender / Merchant</th>
                <th>Amount (JMD)</th>
                <th>Platform Fee</th>
                <th>Status</th>
                <th>Time</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td style={{ fontFamily: 'var(--font-mono)', fontSize: '12px' }}>TX-8920192</td>
                <td><span className="badge badge-emerald">Merchant POS</span></td>
                <td>Mavis Bank Coffee Co.</td>
                <td style={{ fontWeight: 700 }}>$12,500.00</td>
                <td style={{ color: 'var(--emerald-primary)', fontWeight: 600 }}>$187.50</td>
                <td><span className="badge badge-emerald">SETTLED</span></td>
                <td style={{ color: 'var(--text-secondary)', fontSize: '12px' }}>2 mins ago</td>
              </tr>
              <tr>
                <td style={{ fontFamily: 'var(--font-mono)', fontSize: '12px' }}>TX-8920191</td>
                <td><span className="badge badge-cyan">Lynk BOJ Top-Up</span></td>
                <td>Hixroy Walker</td>
                <td style={{ fontWeight: 700 }}>$50,000.00</td>
                <td style={{ color: 'var(--emerald-primary)', fontWeight: 600 }}>$0.00 (Promo)</td>
                <td><span className="badge badge-emerald">SETTLED</span></td>
                <td style={{ color: 'var(--text-secondary)', fontSize: '12px' }}>8 mins ago</td>
              </tr>
              <tr>
                <td style={{ fontFamily: 'var(--font-mono)', fontSize: '12px' }}>TX-8920190</td>
                <td><span className="badge badge-amber">P2P Transfer</span></td>
                <td>Marcus S. → Shenseea P.</td>
                <td style={{ fontWeight: 700 }}>$4,500.00</td>
                <td style={{ color: 'var(--emerald-primary)', fontWeight: 600 }}>$45.00</td>
                <td><span className="badge badge-emerald">SETTLED</span></td>
                <td style={{ color: 'var(--text-secondary)', fontSize: '12px' }}>15 mins ago</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default PlatformOverview;
