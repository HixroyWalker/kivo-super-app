import React from 'react';
import {
  FileSpreadsheet,
  Download,
  Calendar,
  CheckCircle2,
  AlertTriangle,
} from 'lucide-react';

const TajReports = () => {
  return (
    <div>
      <div style={{ marginBottom: '28px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: 800, letterSpacing: '-0.5px', marginBottom: '6px' }}>
            Tax Administration Jamaica (TAJ) GCT-03 Audit Desk
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
            Automated General Consumption Tax (15%) reconciliation and eServices export forms for Jamaican tax filings.
          </p>
        </div>
        <button className="btn btn-primary" onClick={() => alert('TAJ GCT-03 Return Package downloaded in CSV and PDF!')}>
          <Download size={16} /> Download Monthly GCT-03 Return (eServices Form)
        </button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px', marginBottom: '28px' }}>
        <div className="card">
          <h3 style={{ fontSize: '16px', fontWeight: 700, marginBottom: '16px' }}>Current Filing Period Summary (August 2026)</h3>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0', borderBottom: '1px solid var(--border-subtle)' }}>
              <span style={{ color: 'var(--text-secondary)' }}>Gross Taxable Supplies (Standard 15% Rate)</span>
              <strong style={{ fontFamily: 'var(--font-mono)' }}>JMD $84,520,000.00</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0', borderBottom: '1px solid var(--border-subtle)' }}>
              <span style={{ color: 'var(--text-secondary)' }}>Output Tax Collected (15% on Gross Sales)</span>
              <strong style={{ color: 'var(--emerald-primary)', fontFamily: 'var(--font-mono)' }}>JMD $12,678,000.00</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 0', borderBottom: '1px solid var(--border-subtle)' }}>
              <span style={{ color: 'var(--text-secondary)' }}>Allowable Input Tax Deductions (Business Expenses)</span>
              <strong style={{ color: 'var(--cyan-accent)', fontFamily: 'var(--font-mono)' }}>- JMD $3,140,500.00</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '16px 0', borderTop: '2px solid var(--border-subtle)' }}>
              <span style={{ fontWeight: 700, fontSize: '16px' }}>Net GCT Payable to Tax Administration Jamaica</span>
              <strong style={{ color: 'var(--amber-warning)', fontSize: '20px', fontFamily: 'var(--font-mono)' }}>
                JMD $9,537,500.00
              </strong>
            </div>
          </div>
        </div>

        <div className="card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--emerald-primary)', marginBottom: '12px' }}>
              <CheckCircle2 size={20} />
              <h4 style={{ fontWeight: 700 }}>eServices Compliant</h4>
            </div>
            <p style={{ fontSize: '13px', color: 'var(--text-secondary)', lineHeight: 1.5, marginBottom: '16px' }}>
              All merchant transactions are hashed with cryptographic receipts and are fully pre-reconciled against TAJ GCT-03 statutory guidelines.
            </p>
            <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
              Filing Due Date: <strong>September 30, 2026</strong>
            </div>
          </div>

          <button className="btn btn-secondary" style={{ width: '100%', marginTop: '20px' }}>
            <FileSpreadsheet size={16} /> View Line-by-Line Tax Breakdown
          </button>
        </div>
      </div>
    </div>
  );
};

export default TajReports;
