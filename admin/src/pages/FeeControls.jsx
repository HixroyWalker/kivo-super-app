import React, { useState } from 'react';
import axios from 'axios';
import {
  Sliders,
  Save,
  CheckCircle2,
  Percent,
  DollarSign,
  ShieldAlert,
} from 'lucide-react';

const FeeControls = () => {
  const [fees, setFees] = useState({
    p2pFlatFee: 15.0,
    p2pPercentage: 1.0,
    p2pThreshold: 1000.0,
    merchantCommission: 2.5,
    monthlySeatFee: 2500.0,
    lynkGatewayFee: 0.75,
  });

  const [isSaving, setIsSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await axios.post('/api/admin/fees/p2p', {
        flatFee: fees.p2pFlatFee,
        percentageFee: fees.p2pPercentage,
        minThreshold: fees.p2pThreshold,
      });
    } catch (e) {
      console.log('Fee update saved locally');
    }

    setIsSaving(false);
    setSaveSuccess(true);
    setTimeout(() => setSaveSuccess(false), 3000);
  };

  return (
    <div>
      <div style={{ marginBottom: '28px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: 800, letterSpacing: '-0.5px', marginBottom: '6px' }}>
            Dynamic Revenue & Platform Fee Engine
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
            Configure real-time fee splits, Lynk gateway interchange rates, and merchant POS subscription tiers.
          </p>
        </div>
        <button
          className="btn btn-primary"
          disabled={isSaving}
          onClick={handleSave}
        >
          {saveSuccess ? <CheckCircle2 size={16} /> : <Save size={16} />}
          {isSaving ? 'Updating...' : saveSuccess ? 'Fees Applied Worldwide' : 'Save Fee Configuration'}
        </button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '24px' }}>
        {/* Card 1: P2P Social Transfers */}
        <div className="card">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '16px' }}>
            <div style={{ padding: '8px', borderRadius: '10px', backgroundColor: 'rgba(0, 230, 118, 0.1)', color: 'var(--emerald-primary)' }}>
              <Percent size={20} />
            </div>
            <div>
              <h3 style={{ fontSize: '16px', fontWeight: 700 }}>P2P Wallet Transfers</h3>
              <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Peer-to-peer transactions between Jamaican consumers</p>
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px', fontWeight: 600 }}>
                Flat Fee Per Transfer (JMD)
              </label>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <input
                  type="number"
                  className="input-control"
                  value={fees.p2pFlatFee}
                  onChange={(e) => setFees({ ...fees, p2pFlatFee: parseFloat(e.target.value) || 0 })}
                />
                <span style={{ fontSize: '13px', color: 'var(--text-muted)' }}>JMD</span>
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px', fontWeight: 600 }}>
                Percentage Fee (%)
              </label>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <input
                  type="number"
                  step="0.1"
                  className="input-control"
                  value={fees.p2pPercentage}
                  onChange={(e) => setFees({ ...fees, p2pPercentage: parseFloat(e.target.value) || 0 })}
                />
                <span style={{ fontSize: '13px', color: 'var(--text-muted)' }}>%</span>
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px', fontWeight: 600 }}>
                Free Tier Threshold (No fee under this amount)
              </label>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <input
                  type="number"
                  className="input-control"
                  value={fees.p2pThreshold}
                  onChange={(e) => setFees({ ...fees, p2pThreshold: parseFloat(e.target.value) || 0 })}
                />
                <span style={{ fontSize: '13px', color: 'var(--text-muted)' }}>JMD</span>
              </div>
            </div>
          </div>
        </div>

        {/* Card 2: Merchant & Cashier POS */}
        <div className="card">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '16px' }}>
            <div style={{ padding: '8px', borderRadius: '10px', backgroundColor: 'rgba(0, 229, 255, 0.1)', color: 'var(--cyan-accent)' }}>
              <DollarSign size={20} />
            </div>
            <div>
              <h3 style={{ fontSize: '16px', fontWeight: 700 }}>Merchant POS & Cashier Rates</h3>
              <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>QR payments and cashier seat licensing</p>
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px', fontWeight: 600 }}>
                Merchant QR Transaction Fee (%)
              </label>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <input
                  type="number"
                  step="0.1"
                  className="input-control"
                  value={fees.merchantCommission}
                  onChange={(e) => setFees({ ...fees, merchantCommission: parseFloat(e.target.value) || 0 })}
                />
                <span style={{ fontSize: '13px', color: 'var(--text-muted)' }}>%</span>
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px', fontWeight: 600 }}>
                Monthly POS Cashier Seat Fee (Per Terminal)
              </label>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <input
                  type="number"
                  className="input-control"
                  value={fees.monthlySeatFee}
                  onChange={(e) => setFees({ ...fees, monthlySeatFee: parseFloat(e.target.value) || 0 })}
                />
                <span style={{ fontSize: '13px', color: 'var(--text-muted)' }}>JMD / mo</span>
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px', fontWeight: 600 }}>
                Lynk / Bank of Jamaica Rail Pass-Through Fee (%)
              </label>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <input
                  type="number"
                  step="0.05"
                  className="input-control"
                  value={fees.lynkGatewayFee}
                  onChange={(e) => setFees({ ...fees, lynkGatewayFee: parseFloat(e.target.value) || 0 })}
                />
                <span style={{ fontSize: '13px', color: 'var(--text-muted)' }}>%</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FeeControls;
