const express = require('express');
const admin = require('firebase-admin');

module.exports = (db) => {
  const router = express.Router();

  // Register or update a device FCM token for the user
  router.post('/register-token', async (req, res) => {
    const userId = req.user.uid;
    const { fcmToken, deviceType } = req.body;

    if (!fcmToken) {
        return res.status(400).json({ error: 'fcmToken is required' });
    }

    try {
        await db.collection('users').doc(userId).set({
            fcmTokens: admin.firestore.FieldValue.arrayUnion(fcmToken),
            lastDeviceType: deviceType || 'unknown',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        res.status(200).json({ status: 'SUCCESS' });
    } catch (error) {
        console.error('Error registering FCM token:', error);
        res.status(500).json({ error: 'Failed to register token' });
    }
  });

  // Admin route to broadcast a message to a specific user
  router.post('/send', async (req, res) => {
    const { recipientId, title, body, data } = req.body;

    // TODO: Ideally check if the sender has ADMIN claims here
    if (!recipientId || !title || !body) {
        return res.status(400).json({ error: 'recipientId, title, and body are required' });
    }

    try {
        const userDoc = await db.collection('users').doc(recipientId).get();
        if (!userDoc.exists) {
            return res.status(404).json({ error: 'User not found' });
        }

        const fcmTokens = userDoc.data().fcmTokens || [];
        if (fcmTokens.length === 0) {
            return res.status(400).json({ error: 'User has no registered devices' });
        }

        const message = {
            notification: {
                title,
                body
            },
            data: data || {},
            tokens: fcmTokens
        };

        const response = await admin.messaging().sendMulticast(message);
        
        // Log the notification for in-app viewing
        await db.collection('notifications').add({
            userId: recipientId,
            title,
            body,
            data: data || {},
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        res.status(200).json({ 
            status: 'SUCCESS', 
            successCount: response.successCount, 
            failureCount: response.failureCount 
        });
    } catch (error) {
        console.error('Error sending notification:', error);
        res.status(500).json({ error: 'Failed to send notification' });
    }
  });

  return router;
};
