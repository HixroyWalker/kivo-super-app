const request = require('supertest');
const express = require('express');

const mockVerifyIdToken = jest.fn().mockResolvedValue({ uid: 'mock_user_1', email: 'test@kivo.com' });

// Mock Firebase Admin
jest.mock('firebase-admin', () => {
  const firestoreMock = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    get: jest.fn(),
    set: jest.fn(),
    update: jest.fn(),
  };

  firestoreMock.runTransaction = jest.fn((callback) => {
    const t = {
      get: jest.fn(),
      update: jest.fn(),
      set: jest.fn(),
    };
    return callback(t);
  });

  return {
    firestore: () => firestoreMock,
    auth: () => ({
      verifyIdToken: mockVerifyIdToken
    }),
    credential: { cert: jest.fn() },
    initializeApp: jest.fn()
  };
});

const admin = require('firebase-admin');
const db = admin.firestore();

// Setup app
const app = express();
app.use(express.json());

const requireAuth = require('../../src/middleware/authMiddleware');
const walletRoutes = require('../../src/routes/wallet');
app.use('/api/wallet', requireAuth, walletRoutes(db));

describe('Wallet Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockVerifyIdToken.mockResolvedValue({ uid: 'mock_user_1', email: 'test@kivo.com' });
  });

  it('should successfully execute a P2P transfer if funds are sufficient', async () => {
    // Mock the transaction getting sender and recipient documents
    db.runTransaction.mockImplementation(async (callback) => {
        const t = {
            get: jest.fn()
              .mockResolvedValueOnce({ exists: true, data: () => ({ wallet_balance: 1000 }) }) // Sender
              .mockResolvedValueOnce({ exists: true, data: () => ({ wallet_balance: 500 }) })  // Recipient
              .mockResolvedValueOnce({ exists: false }), // Staff Fee Config (assume no override)
            update: jest.fn(),
            set: jest.fn(),
        };
        await callback(t);
        return { status: 'SUCCESS' };
    });

    const res = await request(app)
      .post('/api/wallet/transfer')
      .set('Authorization', 'Bearer MOCK_VALID_JWT')
      .send({
        senderId: 'mock_user_1',
        recipientId: 'mock_user_2',
        amount: 250,
        note: 'Thanks!'
      });

    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual('SUCCESS');
    expect(db.runTransaction).toHaveBeenCalledTimes(1);
  });

  it('should reject a transfer if the token is invalid', async () => {
    mockVerifyIdToken.mockRejectedValueOnce(new Error('Invalid token'));

    const res = await request(app)
      .post('/api/wallet/transfer')
      .set('Authorization', 'Bearer MOCK_INVALID_JWT')
      .send({
        senderId: 'mock_user_1',
        recipientId: 'mock_user_2',
        amount: 250
      });

    expect(res.statusCode).toEqual(401);
    expect(res.body.error).toContain('Unauthorized');
  });
});
