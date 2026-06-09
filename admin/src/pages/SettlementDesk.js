import React, { useState, useEffect } from 'react';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import axios from 'axios';

const SettlementDesk = () => {
  const [data, setData] = useState([]);

  useEffect(() => {
    // Fetch settlement stats
    axios.get('/api/admin/settlements').then(res => setData(res.data));
  }, []);

  return (
    <div style={{ padding: '20px', backgroundColor: '#0F0F1E', color: '#FFF', height: '100vh' }}>
      <h1>Settlement Desk</h1>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
        <div style={{ backgroundColor: 'rgba(255,255,255,0.05)', padding: '20px', borderRadius: '15px' }}>
          <h3>Multi-Merchant Splits</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={data}>
              <XAxis dataKey="merchant_name" stroke="#999" />
              <YAxis stroke="#999" />
              <Tooltip contentStyle={{ backgroundColor: '#1A1A2E', border: 'none' }} />
              <Bar dataKey="total_split" fill="#6C63FF" radius={[5, 5, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
        
        <div style={{ backgroundColor: 'rgba(255,255,255,0.05)', padding: '20px', borderRadius: '15px' }}>
          <h3>Pending Fee Collection</h3>
          {/* Data table for fees */}
        </div>
      </div>
    </div>
  );
};

export default SettlementDesk;
