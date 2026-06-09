import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, FlatList, StyleSheet, KeyboardAvoidingView, Platform } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

const ChatScreen = ({ route }: any) => {
  const { recipient_name } = route.params || { recipient_name: 'Contact' };
  const [message, setMessage] = useState('');
  const [messages, setMessages] = useState([
    { id: '1', sender: 'other', text: 'Hey, did you get my Unity Gift?' },
    { id: '2', sender: 'me', text: 'Just checked! Thanks so much 💜' },
  ]);

  const sendMessage = () => {
    if (!message.trim()) return;
    setMessages([...messages, { id: Date.now().toString(), sender: 'me', text: message }]);
    setMessage('');
  };

  return (
    <KeyboardAvoidingView 
      style={styles.container} 
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={90}
    >
      <View style={styles.header}>
        <Text style={styles.headerTitle}>{recipient_name}</Text>
      </View>

      <FlatList
        data={messages}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View style={[styles.messageBubble, item.sender === 'me' ? styles.myMessage : styles.otherMessage]}>
            <Text style={styles.messageText}>{item.text}</Text>
          </View>
        )}
        contentContainerStyle={styles.messageList}
      />

      <View style={styles.inputContainer}>
        <TouchableOpacity style={styles.paymentButton}>
          <Ionicons name="gift-outline" size={24} color="#6C63FF" />
        </TouchableOpacity>
        <TextInput
          style={styles.input}
          placeholder="Type a message..."
          placeholderTextColor="#999"
          value={message}
          onChangeText={setMessage}
        />
        <TouchableOpacity style={styles.sendButton} onPress={sendMessage}>
          <Ionicons name="send" size={24} color="#6C63FF" />
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0F0F1E' },
  header: { padding: 20, borderBottomWidth: 1, borderBottomColor: 'rgba(255,255,255,0.1)', alignItems: 'center' },
  headerTitle: { color: '#FFF', fontSize: 18, fontWeight: 'bold' },
  messageList: { padding: 20 },
  messageBubble: { padding: 12, borderRadius: 15, marginBottom: 10, maxWidth: '80%' },
  myMessage: { alignSelf: 'flex-end', backgroundColor: '#6C63FF' },
  otherMessage: { alignSelf: 'flex-start', backgroundColor: 'rgba(255,255,255,0.1)' },
  messageText: { color: '#FFF' },
  inputContainer: { flexDirection: 'row', padding: 15, backgroundColor: '#1A1A2E', alignItems: 'center' },
  paymentButton: { marginRight: 10 },
  input: { flex: 1, color: '#FFF', padding: 10, backgroundColor: 'rgba(255,255,255,0.05)', borderRadius: 20, marginRight: 10 },
  sendButton: { padding: 5 }
});

export default ChatScreen;
