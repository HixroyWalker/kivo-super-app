import React, { useState } from 'react';
import { Routes, Route } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import PlatformOverview from './pages/PlatformOverview';
import KycReviewDesk from './pages/KycReviewDesk';
import SettlementDesk from './pages/SettlementDesk';
import FeeControls from './pages/FeeControls';
import MerchantManager from './pages/MerchantManager';
import TajReports from './pages/TajReports';
import { Bell, Search, Globe, Shield } from 'lucide-react';

function App() {
  const [pendingKycCount] = useState(3);

  return (
    <div className="admin-layout">
      {/* Fixed Sidebar */}
      <Sidebar pendingKycCount={pendingKycCount} />

      {/* Main Content Area */}
      <div className="admin-main">
        {/* Sticky Header */}
        <header className="admin-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: 'var(--text-secondary)' }}>
              <Globe size={16} color="var(--emerald-primary)" />
              <span>Production Region: <strong>Kingston, Jamaica (caribbean-south1)</strong></span>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '6px 12px', borderRadius: '20px', backgroundColor: 'rgba(0, 230, 118, 0.1)', color: 'var(--emerald-primary)', fontSize: '12px', fontWeight: 600 }}>
              <Shield size={14} />
              <span>Bank of Jamaica API: Connected</span>
            </div>
            <button className="btn btn-secondary" style={{ padding: '8px', borderRadius: '50%' }}>
              <Bell size={18} />
            </button>
          </div>
        </header>

        {/* Dynamic Page Router */}
        <main className="admin-content">
          <Routes>
            <Route path="/" element={<PlatformOverview />} />
            <Route path="/kyc-desk" element={<KycReviewDesk />} />
            <Route path="/settlements" element={<SettlementDesk />} />
            <Route path="/fee-controls" element={<FeeControls />} />
            <Route path="/merchants" element={<MerchantManager />} />
            <Route path="/taj-reports" element={<TajReports />} />
          </Routes>
        </main>
      </div>
    </div>
  );
}

export default App;
