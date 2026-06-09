import React, { useState, useEffect } from 'react';
import axios from 'axios';

const FeeControls = () => {
  const [settings, setSettings] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchSettings();
  }, []);

  const fetchSettings = async () => {
    const res = await axios.get('/api/admin/settings');
    setSettings(res.data);
    setLoading(false);
  };

  const updateSetting = async (key, newValue) => {
    await axios.post('/api/admin/settings/update', { key, value: newValue });
    fetchSettings();
  };

  return (
    <div style={{ padding: '40px', backgroundColor: '#0F0F1E', color: '#FFF', minHeight: '100vh' }}>
      <h1>Revenue & Fee Controls</h1>
      <p style={{ color: '#999' }}>Adjust the dynamic fee engine across the KIVO ecosystem.</p>
      
      <div style={{ marginTop: '30px', display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '20px' }}>
        {settings.map((s) => (
          <div key={s.key} style={{ backgroundColor: 'rgba(255,255,255,0.05)', padding: '20px', borderRadius: '15px' }}>
            <h3 style={{ color: '#6C63FF', margin: '0 0 10px 0' }}>{s.key.replace(/_/g, ' ').toUpperCase()}</h3>
            <p style={{ fontSize: '14px', color: '#999', marginBottom: '15px' }}>{s.description}</p>
            <div style={{ display: 'flex', gap: '10px' }}>
              <input
                type="text"
                defaultValue={s.value}
                style={{ flex: 1, backgroundColor: '#1A1A2E', border: '1px solid #444', color: '#FFF', padding: '10px', borderRadius: '8px' }}
                onBlur={(e) => updateSetting(s.key, e.target.value)}
              />
              <div style={{ padding: '10px', color: '#00FFCC', fontWeight: 'bold' }}>✓</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default FeeControls;
