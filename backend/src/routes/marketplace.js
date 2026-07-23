const express = require('express');

module.exports = (db) => {
  const router = express.Router();

  // Fetch Marketplace Catalog
  router.get('/products', async (req, res) => {
    try {
      // In production, implement pagination and category filtering here
      const productsRef = db.collection('products').limit(50);
      const snapshot = await productsRef.get();
      
      const products = [];
      snapshot.forEach(doc => {
        products.push({ id: doc.id, ...doc.data() });
      });

      res.status(200).json(products);
    } catch (error) {
      console.error('Fetch Products Error:', error);
      res.status(500).json({ error: 'Failed to fetch catalog' });
    }
  });

  return router;
};
