import React from 'react';
import ChatScreen from '@/src/features/social/ChatScreen';

export default function MessagesTab() {
  // ChatScreen expects a 'route' prop from classic React Navigation,
  // but it has a fallback so we can just render it.
  return <ChatScreen route={{ params: { recipient_name: 'Kivo Support' } }} />;
}
