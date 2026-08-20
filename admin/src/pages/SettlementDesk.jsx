import React, { useState } from 'react';
import {
  Landmark,
  ArrowDownRight,
  CheckCircle,
  Download,
  Clock,
  Layers,
} from 'lucide-react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

const merchantSplitData = [
  { merchant_name: 'Mavis Bank Coffee', total_split: 480000, fee: 7200 },
  { merchant_name: 'Kingston Leather', total_split: 320000, fee: 4800 },
  { merchant_name: 'Island Tech Depot', total_split: 640000, fee: 9600 },
  { merchant_name: 'Mama Grace Spices', total_split: 210000, fee: 3150 },
  { merchant_name: 'Kestrel Advisory', total_split: 550000, fee: 8250 },
];

const pendingBatches = [
  {
    batchId: 'BATCH-JM-2026-08A',
    merchantCount: 42,
    totalGross: 'JMD $4,850,000.00',
    platformFees: 'JMD $72,750.00',
    netPayout: 'JMD $4,777,250.00',
    bankRail: 'Lynk / BOJ Jam-Dex',
    scheduledFor: 'Today at 5:00 PM EST',
    status: 'READY_FOR_SETTLEMENT',
  },
  {
    batchId: 'BATCH-JM-2026-08B',
    merchantCount: 18,
    totalGross: 'JMD $1,240,000.00',
    platformFees: 'JMD $18,600.00',
    netPayout: 'JMD $1,221,400.00',
    bankRail: 'Scotiabank / NCB Direct ACH',
    scheduledFor: 'Tomorrow at 9:00 AM EST',
    status: 'QUEUED',
  },
];

const SettlementDesk = () => {
  const [batches, setBatches] = useState(pendingBatches);
  const [successMsg, setSuccessMsg] = useState(null);

  const triggerSettlement = (batchId) => {
    setBatches(prev => prev.filter(b => b.batchId !== batchId));
    setSuccessMsg(`Batch ${batchId} has been submitted to Lynk / BOJ Jam-Dex gateway for immediate distribution!`);
    setTimeout(() => setSuccessMsg(null), 4000);
  };

  return (
    <div>
      <div style={{ marginBottom: '28px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: 800, letterSpacing: '-0.5px', marginBottom: '6px' }}>
            Merchant Settlement & Payout Desk
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
            Reconciliation and automated multi-merchant payout distributions via Bank of Jamaica and Lynk rails.
          </p>
        </div>
        <button className="btn btn-secondary">
          <Download size={16} /> Export Settlement Ledger (CSV)
        </button>
      </div>

      {successMsg && (
        <div style={{
          padding: '16px 20px',
          borderRadius: '12px',
          marginBottom: '24px',
          backgroundColor: 'rgba(0, 230, 118, 0.15)',
          border: '1px solid rgba(0, 230, 118, 0.3)',
          color: 'var(--emerald-primary)',
          fontWeight: 600,
        }}>
          {successMsg}
        </div>
      )}

      {/* Top Summary Cards */}
      <div className="metrics-grid">
        <div className="card metric-card">
          <div className="metric-header">
            <span className="metric-title">Pending Settlement Volume</span>
            <Landmark size={18} color="var(--cyan-accent)" />
          </div>
          <div className="metric-value" style={{ color: 'var(--cyan-accent)' }}>JMD $6.09M</div>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>60 merchants awaiting payout</div>
        </div>

        <div className="card metric-card">
          <div className="metric-header">
            <span className="metric-title">Accrued Platform Fees</span>
            <ArrowDownRight size={18} color="var(--emerald-primary)" />
          </div>
          <div className="metric-value" style={{ color: 'var(--emerald-primary)' }}>JMD $91.35K</div>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Retained at 1.5% commission</div>
        </div>

        <div className="card metric-card">
          <div className="metric-header">
            <span className="metric-title">Next Settlement Window</span>
            <Clock size={18} color="var(--amber-warning)" />
          </div>
          <div className="metric-value" style={{ fontSize: '22px' }}>5:00 PM EST</div>
          <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Automated BOJ ACH batch</div>
        </div>
      </div>

      {/* Settlement Chart & Batches */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px', marginBottom: '28px' }}>
        <div className="card">
          <h3 style={{ fontSize: '16px', fontWeight: 700, marginBottom: '6px' }}>Top Merchant Settlement Volume (JMD)</h3>
          <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '20px' }}>Current payout cycle allocation</p>
          <div style={{ height: '260px' }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={merchantSplitData}>
                <XAxis dataKey="merchant_name" stroke="#607D8B" fontSize={11} tickLine={false} />
                <YAxis stroke="#607D8B" fontSize={11} tickLine={false} tickFormatter={(v) => `$${(v/1000).toFixed(0)}k`} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#141D26', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '10px' }}
                  formatter={(val) => [`JMD $${Number(val).toLocaleString()}`, 'Payout Amount']}
                />
                <Bar dataKey="total_split" fill="#00E676" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="card">
          <h3 style={{ fontSize: '16px', fontWeight: 700, marginBottom: '6px' }}>Pending Payout Batches</h3>
          <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '16px' }}>Queued for Bank of Jamaica / Lynk execution</p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {batches.map((b) => (
              <div
                key={b.batchId}
                style={{
                  backgroundColor: 'var(--bg-surface-elevated)',
                  border: '1px solid var(--border-subtle)',
                  borderRadius: '12px',
                  padding: '16px',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
                  <div style={{ fontWeight: 700, fontFamily: 'var(--font-mono)', color: 'var(--text-primary)' }}>{b.batchId}</div>
                  <span className="badge badge-emerald">{b.bankRail}</span>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px', fontSize: '13px', marginBottom: '12px' }}>
                  <div>
                    <span style={{ color: 'var(--text-muted)' }}>Merchants:</span> {b.merchantCount}
                  </div>
                  <div>
                    <span style={{ color: 'var(--text-muted)' }}>Net Payout:</span> <strong style={{ color: 'var(--emerald-primary)' }}>{b.netPayout}</strong>
                  </div>
                </div>
                <button
                  className="btn btn-primary"
                  style={{ width: '100%', padding: '8px', fontSize: '13px' }}
                  onClick={() => triggerSettlement(b.batchId)}
                >
                  <CheckCircle size={14} /> Execute Payout Batch Now
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default SettlementDesk;
