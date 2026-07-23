const request = require('supertest');
const express = require('express');

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
    auth: () => ({}),
    credential: { cert: jest.fn() },
    initializeApp: jest.fn()
  };
});

const admin = require('firebase-admin');
const db = admin.firestore();

// Setup app
const app = express();
app.use(express.json());

const transactionRoutes = require('../../src/routes/transactions');
app.use('/api/transactions', transactionRoutes(db));

describe('Transactions Routes (Webhooks)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should process a Lynk webhook top-up successfully if not already processed', async () => {
    // Process topup transaction
    db.runTransaction.mockImplementation(async (callback) => {
        const t = {
            get: jest.fn()
              .mockResolvedValueOnce({ exists: false }) // Event not processed yet
              .mockResolvedValueOnce({ exists: true, data: () => ({ balance: 100 }) }), // User wallet exists
            update: jest.fn(),
            set: jest.fn(),
        };
        await callback(t);
        return { status: 'SUCCESS' };
    });

    const res = await request(app)
      .post('/api/transactions/lynk/webhook')
      .send({
        eventId: 'evt_12345',
        type: 'TOPUP',
        userId: 'mock_user_1',
        amount: 500,
        currency: 'JMD'
      });

    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toEqual('SUCCESS');
    expect(db.runTransaction).toHaveBeenCalledTimes(1);
  });
});
