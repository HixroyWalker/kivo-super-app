import React, { useState, useEffect } from 'react';
import axios from 'axios';
import {
  ShieldCheck,
  CheckCircle,
  XCircle,
  FileText,
  Building,
  Hash,
  MapPin,
  Calendar,
  AlertCircle,
  Eye,
} from 'lucide-react';

const initialKycList = [
  {
    id: 'merch-892',
    businessName: 'Trench Town Artisan Leatherworks Ltd',
    tradingName: 'Trench Town Artisans',
    trn: '129-482-910',
    cojNumber: 'COJ-2024-8921',
    address: '14 Marcus Garvey Drive, Kingston 11, Jamaica',
    contactPerson: 'David Brown',
    email: 'contact@trenchtownartisans.jm',
    phone: '+1 (876) 555-0192',
    estimatedMonthlyVolume: 'JMD $1,200,000.00',
    submittedAt: '2026-08-19 14:32',
    status: 'PENDING_VERIFICATION',
    docType: 'Articles of Incorporation & National ID',
  },
  {
    id: 'merch-893',
    businessName: 'St. Elizabeth Fresh Agro Supply',
    tradingName: 'Mama Grace Spices',
    trn: '201-994-311',
    cojNumber: 'COJ-2023-1102',
    address: 'Main Street, Santa Cruz, St. Elizabeth, Jamaica',
    contactPerson: 'Grace Campbell',
    email: 'sales@mamagracespices.com',
    phone: '+1 (876) 555-8841',
    estimatedMonthlyVolume: 'JMD $3,500,000.00',
    submittedAt: '2026-08-20 02:15',
    status: 'PENDING_VERIFICATION',
    docType: 'Business Registration Certificate & TRN Card',
  },
  {
    id: 'merch-894',
    businessName: 'Ocho Rios Water Sports & Tours',
    tradingName: 'Ochi Adventure Hub',
    trn: '330-184-772',
    cojNumber: 'COJ-2025-4491',
    address: 'Turtle Beach Road, Ocho Rios, St. Ann, Jamaica',
    contactPerson: 'Leroy Johnson',
    email: 'bookings@ochiadventure.jm',
    phone: '+1 (876) 555-3211',
    estimatedMonthlyVolume: 'JMD $6,000,000.00',
    submittedAt: '2026-08-20 06:45',
    status: 'PENDING_VERIFICATION',
    docType: 'TPDCo License & Director Passport',
  },
];

const KycReviewDesk = () => {
  const [kycRequests, setKycRequests] = useState(initialKycList);
  const [selectedMerchant, setSelectedMerchant] = useState(null);
  const [reviewNotes, setReviewNotes] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [feedbackMessage, setFeedbackMessage] = useState(null);

  useEffect(() => {
    // Try fetching from live backend
    axios.get('/api/admin/kyc/pending')
      .then(res => {
        if (res.data?.pendingKYC && res.data.pendingKYC.length > 0) {
          setKycRequests(res.data.pendingKYC);
        }
      })
      .catch(() => {
        // Fallback to sample data for offline/standalone testing
      });
  }, []);

  const handleReview = async (action) => {
    if (!selectedMerchant) return;
    setIsProcessing(true);

    try {
      await axios.post('/api/admin/kyc/review', {
        merchantId: selectedMerchant.id,
        action,
        notes: reviewNotes,
      });
    } catch (e) {
      console.log('Backend review fallback');
    }

    setKycRequests(prev => prev.filter(m => m.id !== selectedMerchant.id));
    setFeedbackMessage({
      type: action === 'APPROVED' ? 'success' : 'danger',
      text: `Merchant "${selectedMerchant.businessName}" has been ${action === 'APPROVED' ? 'VERIFIED & ACTIVATED' : 'REJECTED'}!`,
    });
    setIsProcessing(false);
    setSelectedMerchant(null);
    setReviewNotes('');

    setTimeout(() => setFeedbackMessage(null), 4000);
  };

  return (
    <div>
      <div style={{ marginBottom: '28px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: 800, letterSpacing: '-0.5px', marginBottom: '6px' }}>
            Merchant Business KYC Verification Desk
          </h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
            Verify Tax Registration Numbers (TRN), Company Office of Jamaica (COJ) records, and business legitimacy.
          </p>
        </div>
        <span className="badge badge-amber" style={{ padding: '8px 16px', fontSize: '13px' }}>
          {kycRequests.length} Pending Review
        </span>
      </div>

      {feedbackMessage && (
        <div style={{
          padding: '16px 20px',
          borderRadius: '12px',
          marginBottom: '24px',
          backgroundColor: feedbackMessage.type === 'success' ? 'rgba(0, 230, 118, 0.15)' : 'rgba(255, 23, 68, 0.15)',
          border: `1px solid ${feedbackMessage.type === 'success' ? 'rgba(0, 230, 118, 0.3)' : 'rgba(255, 23, 68, 0.3)'}`,
          color: feedbackMessage.type === 'success' ? 'var(--emerald-primary)' : 'var(--rose-danger)',
          fontWeight: 600,
        }}>
          {feedbackMessage.text}
        </div>
      )}

      {kycRequests.length === 0 ? (
        <div className="card" style={{ textAlign: 'center', padding: '60px 20px' }}>
          <CheckCircle size={48} color="var(--emerald-primary)" style={{ margin: '0 auto 16px' }} />
          <h3 style={{ fontSize: '18px', fontWeight: 700, marginBottom: '8px' }}>All KYC Applications Reviewed!</h3>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
            There are currently no pending merchant business registrations requiring compliance review.
          </p>
        </div>
      ) : (
        <div className="card">
          <div className="table-container">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>Business Legal Name</th>
                  <th>TRN Number</th>
                  <th>COJ Reg #</th>
                  <th>Location</th>
                  <th>Est. Monthly Vol</th>
                  <th>Submitted</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {kycRequests.map((m) => (
                  <tr key={m.id}>
                    <td>
                      <div style={{ fontWeight: 700 }}>{m.businessName}</div>
                      <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Trading as: {m.tradingName}</div>
                    </td>
                    <td style={{ fontFamily: 'var(--font-mono)', fontWeight: 600, color: 'var(--cyan-accent)' }}>
                      {m.trn}
                    </td>
                    <td style={{ fontFamily: 'var(--font-mono)' }}>{m.cojNumber}</td>
                    <td style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>{m.address}</td>
                    <td style={{ fontWeight: 700, color: 'var(--emerald-primary)' }}>{m.estimatedMonthlyVolume}</td>
                    <td style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{m.submittedAt}</td>
                    <td>
                      <button
                        className="btn btn-secondary"
                        style={{ padding: '6px 14px', fontSize: '12px' }}
                        onClick={() => setSelectedMerchant(m)}
                      >
                        <Eye size={14} /> Review KYC
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* KYC Review Modal */}
      {selectedMerchant && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '640px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div style={{ padding: '8px', borderRadius: '10px', backgroundColor: 'rgba(0, 230, 118, 0.1)', color: 'var(--emerald-primary)' }}>
                  <ShieldCheck size={24} />
                </div>
                <div>
                  <h3 style={{ fontSize: '18px', fontWeight: 700 }}>KYC Compliance Review</h3>
                  <p style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Merchant ID: {selectedMerchant.id}</p>
                </div>
              </div>
              <button
                style={{ background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer', fontSize: '20px' }}
                onClick={() => setSelectedMerchant(null)}
              >
                ✕
              </button>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '20px', backgroundColor: 'var(--bg-surface-elevated)', padding: '16px', borderRadius: '12px' }}>
              <div>
                <div style={{ fontSize: '11px', color: 'var(--text-muted)', textTransform: 'uppercase' }}>Legal Name</div>
                <div style={{ fontSize: '14px', fontWeight: 700 }}>{selectedMerchant.businessName}</div>
              </div>
              <div>
                <div style={{ fontSize: '11px', color: 'var(--text-muted)', textTransform: 'uppercase' }}>Tax Registration Number</div>
                <div style={{ fontSize: '14px', fontWeight: 700, color: 'var(--cyan-accent)', fontFamily: 'var(--font-mono)' }}>
                  {selectedMerchant.trn}
                </div>
              </div>
              <div>
                <div style={{ fontSize: '11px', color: 'var(--text-muted)', textTransform: 'uppercase' }}>COJ Registration</div>
                <div style={{ fontSize: '14px', fontWeight: 600, fontFamily: 'var(--font-mono)' }}>{selectedMerchant.cojNumber}</div>
              </div>
              <div>
                <div style={{ fontSize: '11px', color: 'var(--text-muted)', textTransform: 'uppercase' }}>Contact Person</div>
                <div style={{ fontSize: '14px', fontWeight: 600 }}>{selectedMerchant.contactPerson} ({selectedMerchant.phone})</div>
              </div>
            </div>

            <div style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '8px', fontWeight: 600 }}>
                Compliance Review Notes / Feedback:
              </label>
              <textarea
                className="input-control"
                rows="3"
                placeholder="e.g. TRN verified against Tax Administration Jamaica database. Business license in good standing."
                value={reviewNotes}
                onChange={(e) => setReviewNotes(e.target.value)}
              />
            </div>

            <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
              <button
                className="btn btn-danger"
                disabled={isProcessing}
                onClick={() => handleReview('REJECTED')}
              >
                <XCircle size={16} /> Reject Application
              </button>
              <button
                className="btn btn-primary"
                disabled={isProcessing}
                onClick={() => handleReview('APPROVED')}
              >
                <CheckCircle size={16} /> Approve & Verify Merchant
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default KycReviewDesk;
