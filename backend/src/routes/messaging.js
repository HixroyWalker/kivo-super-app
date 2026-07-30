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

  // Send a message in a room (TEXT, VOICE, IMAGE, MONEY_TRANSFER)
  router.post('/room/:roomId/messages', async (req, res) => {
    const { roomId } = req.params;
    const { text, type, mediaUrl, audioDuration, transferAmount } = req.body;
    const senderId = req.user.uid;

    try {
      const roomRef = db.collection('chats').doc(roomId);
      const roomDoc = await roomRef.get();

      if (!roomDoc.exists || !roomDoc.data().participants.includes(senderId)) {
          return res.status(403).json({ error: 'Forbidden or Room Not Found' });
      }

      const messageRef = roomRef.collection('messages').doc();
      const msgType = type || 'TEXT'; // TEXT, VOICE, IMAGE, MONEY_TRANSFER

      const payload = {
        id: messageRef.id,
        senderId: senderId,
        type: msgType,
        text: text || '',
        mediaUrl: mediaUrl || '',
        audioDuration: audioDuration || 0,
        transferAmount: transferAmount || 0,
        status: 'SENT', // SENT, DELIVERED, READ
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      };

      await messageRef.set(payload);

      // Update room last message preview
      await roomRef.update({
        lastMessage: text || (msgType === 'VOICE' ? '🎤 Voice Note' : msgType === 'IMAGE' ? '📷 Photo' : '💸 Money Transfer'),
        lastMessageType: msgType,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      res.status(200).json({ status: 'SUCCESS', message: payload });
    } catch (error) {
      console.error('Message Send Error:', error);
      res.status(500).json({ error: 'Failed to send message' });
    }
  });

  // Mark message as read (Blue Ticks)
  router.post('/room/:roomId/messages/:messageId/read', async (req, res) => {
    const { roomId, messageId } = req.params;
    const userId = req.user.uid;

    try {
      const msgRef = db.collection('chats').doc(roomId).collection('messages').doc(messageId);
      await msgRef.update({ status: 'READ', readAt: admin.firestore.FieldValue.serverTimestamp() });
      res.status(200).json({ status: 'SUCCESS' });
    } catch (error) {
      console.error('Read Receipt Error:', error);
      res.status(500).json({ error: 'Failed to mark message as read' });
    }
  });

  // Initiate Audio Voice Call
  router.post('/room/:roomId/calls/audio', async (req, res) => {
    const { roomId } = req.params;
    const callerId = req.user.uid;

    try {
      const callRef = db.collection('chats').doc(roomId).collection('calls').doc();
      const callData = {
        callId: callRef.id,
        callerId,
        type: 'AUDIO',
        status: 'RINGING', // RINGING, CONNECTED, ENDED
        startedAt: admin.firestore.FieldValue.serverTimestamp()
      };
      await callRef.set(callData);
      res.status(200).json({ status: 'SUCCESS', call: callData });
    } catch (error) {
      console.error('Voice Call Error:', error);
      res.status(500).json({ error: 'Failed to initiate audio call' });
    }
  });

  return router;
};
