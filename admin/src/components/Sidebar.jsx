import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  ShieldCheck,
  Landmark,
  Sliders,
  Store,
  FileSpreadsheet,
  LogOut,
  Zap,
} from 'lucide-react';

const Sidebar = ({ pendingKycCount = 3 }) => {
  const navItems = [
    { to: '/', label: 'Overview', icon: LayoutDashboard },
    { to: '/kyc-desk', label: 'KYC Verification', icon: ShieldCheck, badge: pendingKycCount },
    { to: '/settlements', label: 'Settlement Desk', icon: Landmark },
    { to: '/fee-controls', label: 'Fee & Revenue Engine', icon: Sliders },
    { to: '/merchants', label: 'Merchant Directory', icon: Store },
    { to: '/taj-reports', label: 'TAJ GCT-03 Audit', icon: FileSpreadsheet },
  ];

  return (
    <aside className="admin-sidebar">
      {/* Brand Header */}
      <div style={{ padding: '24px', display: 'flex', alignItems: 'center', gap: '12px', borderBottom: '1px solid var(--border-subtle)' }}>
        <div style={{
          width: '36px',
          height: '36px',
          borderRadius: '10px',
          background: 'linear-gradient(135deg, #00E676, #00B0FF)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: '#000',
        }}>
          <Zap size={20} />
        </div>
        <div>
          <div style={{ fontWeight: 800, fontSize: '18px', letterSpacing: '-0.5px' }}>KIVO</div>
          <div style={{ fontSize: '11px', color: 'var(--text-secondary)', fontWeight: 600 }}>ADMIN PORTAL 🇯🇲</div>
        </div>
      </div>

      {/* Navigation Links */}
      <nav style={{ padding: '20px 12px', flex: 1, display: 'flex', flexDirection: 'column', gap: '4px' }}>
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              style={({ isActive }) => ({
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '12px 16px',
                borderRadius: '10px',
                color: isActive ? 'var(--emerald-primary)' : 'var(--text-secondary)',
                backgroundColor: isActive ? 'rgba(0, 230, 118, 0.1)' : 'transparent',
                fontWeight: isActive ? 700 : 500,
                fontSize: '14px',
                textDecoration: 'none',
                transition: 'all 0.2s',
              })}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <Icon size={18} />
                <span>{item.label}</span>
              </div>
              {item.badge > 0 && (
                <span className="badge badge-amber" style={{ fontSize: '10px', padding: '2px 6px' }}>
                  {item.badge}
                </span>
              )}
            </NavLink>
          );
        })}
      </nav>

      {/* Footer Info */}
      <div style={{ padding: '20px', borderTop: '1px solid var(--border-subtle)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '12px' }}>
          <div style={{
            width: '36px',
            height: '36px',
            borderRadius: '50%',
            backgroundColor: 'var(--bg-surface-elevated)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: 'var(--emerald-primary)',
            fontWeight: 'bold',
          }}>
            HW
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: '13px', fontWeight: 'bold', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              Hixroy Walker
            </div>
            <div style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>Super Administrator</div>
          </div>
        </div>
        <button
          className="btn btn-secondary"
          style={{ width: '100%', padding: '8px', fontSize: '12px', justifyContent: 'center' }}
        >
          <LogOut size={14} />
          Sign Out
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
