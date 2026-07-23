const express = require('express');
const admin = require('firebase-admin');

module.exports = (db) => {
  const router = express.Router();

  // Create or get an existing chat room
  router.post('/room', async (req, res) => {
    const { buyerId, sellerId, productId } = req.body;
    // req.user is populated by requireAuth middleware
    if (!req.user || (req.user.uid !== buyerId && req.user.uid !== sellerId)) {
        return res.status(403).json({ error: 'Forbidden' });
    }

    try {
      // Typically you'd query for an existing room, but for simplicity here we just generate an ID
      const roomId = [buyerId, sellerId, productId].sort().join('_');
      
      const roomRef = db.collection('chats').doc(roomId);
      await roomRef.set({
        participants: [buyerId, sellerId],
        productId: productId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      res.status(200).json({ roomId, status: 'SUCCESS' });
    } catch (error) {
      console.error('Chat Room Error:', error);
      res.status(500).json({ error: 'Failed to initialize chat' });
    }
  });

  // Send a message in a room
  router.post('/room/:roomId/messages', async (req, res) => {
    const { roomId } = req.params;
    const { text } = req.body;
    const senderId = req.user.uid;

    try {
      const roomRef = db.collection('chats').doc(roomId);
      const roomDoc = await roomRef.get();

      if (!roomDoc.exists || !roomDoc.data().participants.includes(senderId)) {
          return res.status(403).json({ error: 'Forbidden or Room Not Found' });
      }

      const messageRef = roomRef.collection('messages').doc();
      await messageRef.set({
        senderId: senderId,
        text: text,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });

      // Update room timestamp for sorting
      await roomRef.update({ updatedAt: admin.firestore.FieldValue.serverTimestamp() });

      res.status(200).json({ status: 'SUCCESS' });
    } catch (error) {
      console.error('Message Send Error:', error);
      res.status(500).json({ error: 'Failed to send message' });
    }
  });

  return router;
};
