import React, { useState } from 'react';
import {
  Store,
  Search,
  CheckCircle,
  Lock,
  Unlock,
  MoreVertical,
  MapPin,
  TrendingUp,
} from 'lucide-react';

const initialMerchants = [
  {
    id: 'M-001',
    name: 'Mavis Bank Coffee Co.',
    category: 'Agro & Coffee',
    location: 'St. Andrew, Jamaica',
    trn: '109-223-891',
    totalVolume: 'JMD $14,200,000.00',
    terminalsCount: 6,
    status: 'ACTIVE',
  },
  {
    id: 'M-002',
    name: 'Trench Town Artisans',
    category: 'Fashion & Crafts',
    location: 'Kingston, Jamaica',
    trn: '129-482-910',
    totalVolume: 'JMD $3,850,000.00',
    terminalsCount: 2,
    status: 'ACTIVE',
  },
  {
    id: 'M-003',
    name: 'Island Tech Depot',
    category: 'Electronics',
    location: 'Montego Bay, Jamaica',
    trn: '304-112-901',
    totalVolume: 'JMD $28,900,000.00',
    terminalsCount: 12,
    status: 'ACTIVE',
  },
  {
    id: 'M-004',
    name: 'Mama Grace Spices',
    category: 'Produce & Agro',
    location: 'Santa Cruz, Jamaica',
    trn: '201-994-311',
    totalVolume: 'JMD $1,940,000.00',
    terminalsCount: 1,
    status: 'ACTIVE',
  },
  {
    id: 'M-005',
    name: 'Kingston Quick Liquors',
    category: 'Beverage & Retail',
    location: 'Half Way Tree, Kingston',
    trn: '419-002-184',
    totalVolume: 'JMD $9,400,000.00',
    terminalsCount: 4,
    status: 'FROZEN',
  },
];

const MerchantManager = () => {
  const [merchants, setMerchants] = useState(initialMerchants);
  const [searchTerm, setSearchTerm] = useState('');

  const toggleStatus = (id) => {
    setMerchants(prev =>
      prev.map(m => {
        if (m.id === id) {
          return {
            ...m,
            status: m.status === 'ACTIVE' ? 'FROZEN' : 'ACTIVE',
          };
        }
        return m;
      })
    );
  };

  const filtered = merchants.filter(m =>
    m.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    m.trn.includes(searchTerm) ||
    m.category.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div>
      <div style={{ marginBottom: '28px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: 800, letterSpacing: '-0.5px', marginBottom: '6px' }}>
            Merchant Directory & Terminals
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
            Inspect registered businesses, manage active POS terminals, and enforce account freezes.
          </p>
        </div>
      </div>

      <div className="card" style={{ marginBottom: '24px', padding: '16px 20px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <Search size={18} color="var(--text-muted)" />
          <input
            type="text"
            placeholder="Search by merchant name, category, or TRN..."
            className="input-control"
            style={{ border: 'none', backgroundColor: 'transparent', padding: '0' }}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      <div className="card">
        <div className="table-container">
          <table className="admin-table">
            <thead>
              <tr>
                <th>Merchant Name</th>
                <th>Category</th>
                <th>TRN Number</th>
                <th>Location</th>
                <th>Terminals</th>
                <th>Lifetime Volume</th>
                <th>Status</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((m) => (
                <tr key={m.id}>
                  <td>
                    <div style={{ fontWeight: 700 }}>{m.name}</div>
                    <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>ID: {m.id}</div>
                  </td>
                  <td><span className="badge badge-cyan">{m.category}</span></td>
                  <td style={{ fontFamily: 'var(--font-mono)', fontSize: '13px' }}>{m.trn}</td>
                  <td style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>{m.location}</td>
                  <td style={{ fontWeight: 600 }}>{m.terminalsCount} Active</td>
                  <td style={{ fontWeight: 700, color: 'var(--emerald-primary)' }}>{m.totalVolume}</td>
                  <td>
                    <span className={`badge ${m.status === 'ACTIVE' ? 'badge-emerald' : 'badge-rose'}`}>
                      {m.status}
                    </span>
                  </td>
                  <td>
                    <button
                      className={`btn ${m.status === 'ACTIVE' ? 'btn-danger' : 'btn-primary'}`}
                      style={{ padding: '6px 12px', fontSize: '12px' }}
                      onClick={() => toggleStatus(m.id)}
                    >
                      {m.status === 'ACTIVE' ? <Lock size={13} /> : <Unlock size={13} />}
                      {m.status === 'ACTIVE' ? 'Freeze' : 'Activate'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default MerchantManager;
