import React, { useState, useEffect } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  FlatList, 
  TouchableOpacity, 
  TextInput, 
  Modal, 
  ActivityIndicator, 
  Alert,
  Dimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import FeedScreen from '@/src/features/social/FeedScreen';
import api from '@/src/utils/api';

const { width } = Dimensions.get('window');

interface Product {
  id: string;
  name: string;
  price: string;
}

export default function SocialDiscoverScreen() {
  const [posts, setPosts] = useState<any[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  // New Post State
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newPostContent, setNewPostContent] = useState('');
  const [newPostYoutube, setNewPostYoutube] = useState('');
  const [selectedProductId, setSelectedProductId] = useState<string | null>(null);
  const [submittingPost, setSubmittingPost] = useState(false);

  // Fetch Feed & Products Catalog
  const fetchData = async () => {
    try {
      const [postRes, prodRes] = await Promise.all([
        api.get('/api/wallet/posts'),
        api.get('/api/wallet/products')
      ]);
      setPosts(postRes.data);
      setProducts(prodRes.data);
    } catch (error) {
      console.error('Error fetching social discover data:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      const postRes = await api.get('/api/wallet/posts');
      setPosts(postRes.data);
    } catch (error) {
      console.error('Refresh feed error:', error);
    } finally {
      setRefreshing(false);
    }
  };

  // Submit Post
  const handleCreatePost = async () => {
    if (!newPostContent.trim()) {
      Alert.alert('Content Required', 'Please type something on your mind to share.');
      return;
    }

    setSubmittingPost(true);
    try {
      let postType = 'TEXT';
      if (newPostYoutube) postType = 'VIDEO';
      else if (selectedProductId) postType = 'PRODUCT';

      await api.post('/api/wallet/posts', {
        content: newPostContent,
        youtube_link: newPostYoutube || null,
        product_id: selectedProductId || null,
        post_type: postType
      });

      Alert.alert('Success', 'Your post has been shared to KIVO Social Feed.');
      
      // Reset
      setNewPostContent('');
      setNewPostYoutube('');
      setSelectedProductId(null);
      setShowCreateModal(false);
      
      // Refresh feed
      handleRefresh();
    } catch (error: any) {
      Alert.alert('Failed to Share', error.response?.data?.error || 'Unknown error occurred.');
    } finally {
      setSubmittingPost(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Premium Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.headerSubtitle}>COMMUNITY LED COMMERCE</Text>
          <Text style={styles.headerTitle}>KIVO Discover</Text>
        </View>
        <TouchableOpacity style={styles.createButton} onPress={() => setShowCreateModal(true)}>
          <Ionicons name="create-outline" size={22} color="#00FFCC" />
          <Text style={styles.createButtonText}>Post</Text>
        </TouchableOpacity>
      </View>

      {/* Main Social Feed */}
      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#6C63FF" />
          <Text style={styles.loadingText}>Connecting to social feed...</Text>
        </View>
      ) : (
        <FeedScreen 
          posts={posts} 
          refreshing={refreshing} 
          onRefresh={handleRefresh} 
        />
      )}

      {/* Create Shoppable Post Modal */}
      <Modal visible={showCreateModal} transparent animationType="slide">
        <View style={styles.modalBg}>
          <View style={styles.modalContent}>
            {/* Modal Header */}
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Share a Post</Text>
              <TouchableOpacity onPress={() => setShowCreateModal(false)}>
                <Ionicons name="close-circle" size={26} color="#FFF" />
              </TouchableOpacity>
            </View>

            {/* Inputs */}
            <Text style={styles.label}>Post Text Content</Text>
            <TextInput
              style={[styles.modalInput, { height: 90, textAlignVertical: 'top' }]}
              value={newPostContent}
              onChangeText={setNewPostContent}
              placeholder="What is on your mind? Highlight products or events!"
              placeholderTextColor="#555"
              multiline
              numberOfLines={4}
            />

            <Text style={styles.label}>YouTube Video Link (Optional)</Text>
            <TextInput
              style={styles.modalInput}
              value={newPostYoutube}
              onChangeText={setNewPostYoutube}
              placeholder="e.g. https://www.youtube.com/watch?v=..."
              placeholderTextColor="#555"
            />

            {/* Shoppable Product Picker */}
            <Text style={styles.label}>Link Shoppable Item (Optional)</Text>
            <View style={styles.productPickerRow}>
              {products.length === 0 ? (
                <Text style={styles.noProductText}>No active items to link</Text>
              ) : (
                <FlatList
                  horizontal
                  showsHorizontalScrollIndicator={false}
                  data={products}
                  keyExtractor={(item) => item.id}
                  renderItem={({ item }) => (
                    <TouchableOpacity 
                      style={[
                        styles.pickerCard, 
                        selectedProductId === item.id && styles.selectedPickerCard
                      ]}
                      onPress={() => setSelectedProductId(selectedProductId === item.id ? null : item.id)}
                    >
                      <Text style={[
                        styles.pickerCardText,
                        selectedProductId === item.id && styles.selectedPickerCardText
                      ]} numberOfLines={1}>
                        {item.name}
                      </Text>
                      <Text style={styles.pickerCardPrice}>${parseFloat(item.price).toFixed(0)}</Text>
                    </TouchableOpacity>
                  )}
                />
              )}
            </View>

            {/* Actions */}
            <TouchableOpacity 
              style={[styles.submitPostBtn, submittingPost && styles.disabledBtn]}
              onPress={handleCreatePost}
              disabled={submittingPost}
            >
              {submittingPost ? (
                <ActivityIndicator size="small" color="#FFF" />
              ) : (
                <Text style={styles.submitPostBtnText}>Share Shoppable Post</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#090915' },
  header: { 
    flexDirection: 'row', 
    justifyContent: 'space-between', 
    alignItems: 'center', 
    paddingHorizontal: 20, 
    paddingTop: 15,
    paddingBottom: 15,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.05)'
  },
  headerSubtitle: { color: '#6C63FF', fontSize: 10, fontWeight: 'bold', letterSpacing: 2 },
  headerTitle: { color: '#FFF', fontSize: 24, fontWeight: 'bold' },
  createButton: { 
    flexDirection: 'row', 
    alignItems: 'center', 
    backgroundColor: 'rgba(0,255,204,0.1)', 
    paddingHorizontal: 12, 
    paddingVertical: 8, 
    borderRadius: 10,
    borderWidth: 1,
    borderColor: 'rgba(0,255,204,0.2)'
  },
  createButtonText: { color: '#00FFCC', fontSize: 13, fontWeight: 'bold', marginLeft: 4 },
  
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  loadingText: { color: '#888', marginTop: 12 },

  // Modal Styling
  modalBg: { flex: 1, backgroundColor: 'rgba(0,0,0,0.85)', justifyContent: 'center', alignItems: 'center', padding: 20 },
  modalContent: { 
    backgroundColor: '#131326', 
    width: '100%', 
    borderRadius: 25, 
    padding: 24, 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.08)' 
  },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 },
  modalTitle: { color: '#FFF', fontSize: 20, fontWeight: 'bold' },
  label: { color: '#888', fontSize: 12, fontWeight: 'bold', marginBottom: 6, marginTop: 12 },
  modalInput: { 
    backgroundColor: 'rgba(255,255,255,0.05)', 
    borderRadius: 12, 
    color: '#FFF', 
    fontSize: 14, 
    padding: 12, 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.05)',
    marginBottom: 10
  },
  productPickerRow: { marginVertical: 8 },
  noProductText: { color: '#555', fontSize: 13, fontStyle: 'italic' },
  
  pickerCard: { 
    backgroundColor: 'rgba(255,255,255,0.03)', 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.05)',
    paddingVertical: 10,
    paddingHorizontal: 15,
    borderRadius: 10,
    marginRight: 10,
    alignItems: 'center',
    width: 110
  },
  selectedPickerCard: { 
    backgroundColor: 'rgba(108,99,255,0.15)',
    borderColor: '#6C63FF'
  },
  pickerCardText: { color: '#FFF', fontSize: 11, fontWeight: 'bold' },
  selectedPickerCardText: { color: '#00FFCC' },
  pickerCardPrice: { color: '#6C63FF', fontSize: 11, marginTop: 2, fontWeight: 'bold' },
  
  submitPostBtn: { 
    backgroundColor: '#6C63FF', 
    borderRadius: 12, 
    paddingVertical: 14, 
    alignItems: 'center', 
    justifyContent: 'center', 
    marginTop: 24 
  },
  submitPostBtnText: { color: '#FFF', fontSize: 15, fontWeight: 'bold' },
  disabledBtn: { backgroundColor: '#444' }
});
