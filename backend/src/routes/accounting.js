const express = require('express');

module.exports = (db) => {
  const router = express.Router();

  // Fetch Ledger History and Analytics for a User/Merchant
  router.get('/ledger', async (req, res) => {
    // req.user is populated by the requireAuth middleware
    const userId = req.user.uid;

    try {
      // 1. Fetch recent transactions where user is sender OR receiver
      const sentRef = db.collection('transactions').where('senderId', '==', userId).limit(50);
      const receivedRef = db.collection('transactions').where('recipientId', '==', userId).limit(50);
      
      const [sentSnapshot, receivedSnapshot] = await Promise.all([
        sentRef.get(),
        receivedRef.get()
      ]);

      const transactions = [];
      let totalInflow = 0;
      let totalOutflow = 0;

      sentSnapshot.forEach(doc => {
        const data = doc.data();
        transactions.push({ id: doc.id, type: 'SENT', ...data });
        totalOutflow += data.amount || 0;
      });

      receivedSnapshot.forEach(doc => {
        const data = doc.data();
        transactions.push({ id: doc.id, type: 'RECEIVED', ...data });
        totalInflow += data.amount || 0;
      });

      // Sort by timestamp descending
      transactions.sort((a, b) => b.timestamp - a.timestamp);

      // 2. Mock Analytics calculation (In production, this might aggregate over time periods)
      const analytics = {
        totalInflow,
        totalOutflow,
        netBalance: totalInflow - totalOutflow,
        transactionCount: transactions.length
      };

      res.status(200).json({
        analytics,
        ledger: transactions
      });

    } catch (error) {
      console.error('Accounting Error:', error);
      res.status(500).json({ error: 'Failed to fetch ledger data' });
    }
  });

  // Create Invoice
  router.post('/invoices', async (req, res) => {
    const userId = req.user.uid;
    const { customerName, customerEmail, items, dueDate, notes, gctTaxRate } = req.body;

    if (!customerName || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'Customer name and line items are required' });
    }

    try {
      const taxRate = gctTaxRate != null ? parseFloat(gctTaxRate) : 0.15; // 15% Jamaican GCT default
      let subtotal = 0;
      const formattedItems = items.map(item => {
        const itemTotal = (item.quantity || 1) * (item.unitPrice || 0);
        subtotal += itemTotal;
        return {
          description: item.description || 'Item',
          quantity: item.quantity || 1,
          unitPrice: item.unitPrice || 0,
          total: itemTotal
        };
      });

      const gctAmount = subtotal * taxRate;
      const totalAmount = subtotal + gctAmount;

      const invoiceData = {
        userId,
        customerName,
        customerEmail: customerEmail || '',
        items: formattedItems,
        subtotal,
        gctTaxRate: taxRate,
        gctAmount,
        totalAmount,
        status: 'PENDING', // PENDING, PAID, OVERDUE
        dueDate: dueDate || new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString(),
        notes: notes || '',
        createdAt: new Date().toISOString()
      };

      const docRef = await db.collection('invoices').add(invoiceData);
      res.status(201).json({ id: docRef.id, ...invoiceData });
    } catch (error) {
      console.error('Create Invoice Error:', error);
      res.status(500).json({ error: 'Failed to create invoice' });
    }
  });

  // Get Invoices
  router.get('/invoices', async (req, res) => {
    const userId = req.user.uid;

    try {
      const snapshot = await db.collection('invoices').where('userId', '==', userId).get();
      const invoices = [];
      snapshot.forEach(doc => invoices.push({ id: doc.id, ...doc.data() }));
      invoices.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
      res.status(200).json({ invoices });
    } catch (error) {
      console.error('Get Invoices Error:', error);
      res.status(500).json({ error: 'Failed to fetch invoices' });
    }
  });

  // Record Expense
  router.post('/expenses', async (req, res) => {
    const userId = req.user.uid;
    const { category, amount, description, gctPaid } = req.body;

    if (!category || amount == null) {
      return res.status(400).json({ error: 'Category and amount are required' });
    }

    try {
      const expenseData = {
        userId,
        category, // Rent, Utilities, Inventory, Payroll, Marketing, Supplies, Other
        amount: parseFloat(amount),
        description: description || '',
        gctPaid: gctPaid != null ? parseFloat(gctPaid) : parseFloat(amount) * 0.15,
        date: new Date().toISOString()
      };

      const docRef = await db.collection('expenses').add(expenseData);
      res.status(201).json({ id: docRef.id, ...expenseData });
    } catch (error) {
      console.error('Record Expense Error:', error);
      res.status(500).json({ error: 'Failed to record expense' });
    }
  });

  // Get Expenses
  router.get('/expenses', async (req, res) => {
    const userId = req.user.uid;

    try {
      const snapshot = await db.collection('expenses').where('userId', '==', userId).get();
      const expenses = [];
      snapshot.forEach(doc => expenses.push({ id: doc.id, ...doc.data() }));
      expenses.sort((a, b) => new Date(b.date) - new Date(a.date));
      res.status(200).json({ expenses });
    } catch (error) {
      console.error('Get Expenses Error:', error);
      res.status(500).json({ error: 'Failed to fetch expenses' });
    }
  });

  // Profit & Loss (P&L) and Tax Report
  router.get('/reports/pnl', async (req, res) => {
    const userId = req.user.uid;

    try {
      const [invoicesSnap, expensesSnap, txSnap] = await Promise.all([
        db.collection('invoices').where('userId', '==', userId).get(),
        db.collection('expenses').where('userId', '==', userId).get(),
        db.collection('transactions').where('recipientId', '==', userId).get()
      ]);

      let totalRevenue = 0;
      let totalGctCollected = 0;
      invoicesSnap.forEach(doc => {
        const inv = doc.data();
        if (inv.status === 'PAID') {
          totalRevenue += inv.subtotal || 0;
          totalGctCollected += inv.gctAmount || 0;
        }
      });

      txSnap.forEach(doc => {
        totalRevenue += doc.data().amount || 0;
      });

      let totalExpenses = 0;
      let totalGctPaid = 0;
      const expensesByCategory = {};

      expensesSnap.forEach(doc => {
        const exp = doc.data();
        totalExpenses += exp.amount || 0;
        totalGctPaid += exp.gctPaid || 0;
        expensesByCategory[exp.category] = (expensesByCategory[exp.category] || 0) + (exp.amount || 0);
      });

      const netIncome = totalRevenue - totalExpenses;
      const netGctPayable = totalGctCollected - totalGctPaid;

      res.status(200).json({
        report: {
          totalRevenue,
          totalExpenses,
          netIncome,
          expensesByCategory,
          taxSummary: {
            gctCollected: totalGctCollected,
            gctPaid: totalGctPaid,
            netGctPayable
          }
        }
      });
    } catch (error) {
      console.error('PnL Report Error:', error);
      res.status(500).json({ error: 'Failed to generate PnL report' });
    }
  });

  return router;
};
