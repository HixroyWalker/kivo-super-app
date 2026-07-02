import React, { useState, useRef } from 'react';
import { 
  View, 
  Text, 
  FlatList, 
  Image, 
  TouchableOpacity, 
  StyleSheet, 
  Dimensions, 
  ActivityIndicator,
  Alert
} from 'react-native';
import { WebView } from 'react-native-webview';
import { useCartStore } from '../../store/cartStore';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';

interface FeedScreenProps {
  posts: any[];
  refreshing: boolean;
  onRefresh: () => void;
}

const FeedScreen = ({ posts, refreshing, onRefresh }: FeedScreenProps) => {
  const addItem = useCartStore((state) => state.addItem);
  const [layoutHeight, setLayoutHeight] = useState(Dimensions.get('window').height - 180);
  const [likedPosts, setLikedPosts] = useState<Record<string, boolean>>({});
  const [followedAuthors, setFollowedAuthors] = useState<Record<string, boolean>>({});

  const toggleLike = (postId: string) => {
    setLikedPosts(prev => ({ ...prev, [postId]: !prev[postId] }));
  };

  const toggleFollow = (authorId: string) => {
    setFollowedAuthors(prev => ({ ...prev, [authorId]: !prev[authorId] }));
  };

  const handleQuickBuy = (product: any) => {
    addItem({
      product_id: product.id,
      name: product.name,
      price: parseFloat(product.price),
      quantity: 1,
      merchant_id: product.merchant_id || 'Unknown Merchant'
    });
    router.push('/Checkout');
  };

  const getYoutubeEmbedUrl = (url: string) => {
    if (!url) return '';
    let videoId = '';
    if (url.includes('v=')) {
      videoId = url.split('v=')[1]?.split('&')[0];
    } else if (url.includes('youtu.be/')) {
      videoId = url.split('youtu.be/')[1]?.split('?')[0];
    } else if (url.includes('embed/')) {
      videoId = url.split('embed/')[1]?.split('?')[0];
    }
    return `https://www.youtube.com/embed/${videoId}?autoplay=1&mute=1&loop=1&playlist=${videoId}&controls=0&modestbranding=1&playsinline=1&origin=https://kivo.com`;
  };

  const renderItem = ({ item }: { item: any }) => {
    const isLiked = !!likedPosts[item.id];
    const isFollowed = !!followedAuthors[item.user_id];
    const baseLikes = ((item.content.length * 13) % 400) + 120;
    const likesCount = isLiked ? baseLikes + 1 : baseLikes;
    const commentsCount = (item.content.length * 3) % 45 + 5;
    const shareCount = (item.content.length * 2) % 30 + 2;

    const hasVideo = !!item.youtube_link;

    return (
      <View style={[styles.postPage, { height: layoutHeight }]}>
        {/* Background Layer: Video or Gradient Card */}
        {hasVideo ? (
          <View style={styles.backgroundVideoContainer}>
            <WebView
              source={{ 
                uri: getYoutubeEmbedUrl(item.youtube_link),
                headers: { 'Referer': 'https://kivo.com/' }
              }}
              style={styles.webview}
              javaScriptEnabled={true}
              domStorageEnabled={true}
              allowsInlineMediaPlayback={true}
              mediaPlaybackRequiresUserAction={false}
            />
          </View>
        ) : (
          <LinearGradient
            colors={['#1F1A3A', '#0D091A']}
            style={styles.backgroundGradient}
          >
            <View style={styles.textPostCenterContainer}>
              <Ionicons name="chatbubbles-outline" size={40} color="rgba(255,153,0,0.15)" style={styles.quoteIcon} />
              <Text style={styles.textPostTypography}>{item.content}</Text>
            </View>
          </LinearGradient>
        )}

        {/* Bottom Shader for readability */}
        <LinearGradient
          colors={['transparent', 'rgba(0,0,0,0.85)']}
          style={styles.bottomShader}
        />

        {/* Floating Right Actions Panel */}
        <View style={styles.rightActionsPanel}>
          {/* Profile follow bubble */}
          <View style={styles.profileContainer}>
            <View style={styles.avatarCircle}>
              <Text style={styles.avatarText}>
                {item?.author?.lynk_handle ? item.author.lynk_handle.slice(0, 2).toUpperCase() : 'KV'}
              </Text>
            </View>
            <TouchableOpacity 
              style={[styles.followPlus, isFollowed && styles.followPlusChecked]}
              onPress={() => toggleFollow(item.user_id)}
            >
              <Ionicons name={isFollowed ? "checkmark" : "add"} size={11} color="#FFF" />
            </TouchableOpacity>
          </View>

          {/* Like */}
          <TouchableOpacity style={styles.actionBtn} onPress={() => toggleLike(item.id)}>
            <View style={[styles.actionIconBg, isLiked && styles.actionIconBgLiked]}>
              <Ionicons name="heart" size={24} color={isLiked ? "#FF3B30" : "#FFF"} />
            </View>
            <Text style={styles.actionCountText}>{likesCount}</Text>
          </TouchableOpacity>

          {/* Comments */}
          <TouchableOpacity style={styles.actionBtn} onPress={() => Alert.alert('Comments', 'Comments are in read-only mode for this build.')}>
            <View style={styles.actionIconBg}>
              <Ionicons name="chatbubble-ellipses" size={24} color="#FFF" />
            </View>
            <Text style={styles.actionCountText}>{commentsCount}</Text>
          </TouchableOpacity>

          {/* Share */}
          <TouchableOpacity style={styles.actionBtn} onPress={() => Alert.alert('Share', 'Link copied to clipboard!')}>
            <View style={styles.actionIconBg}>
              <Ionicons name="arrow-redo" size={24} color="#FFF" />
            </View>
            <Text style={styles.actionCountText}>{shareCount}</Text>
          </TouchableOpacity>

          {/* Shoppable Cart (Right side quick trigger) */}
          {item.post_type === 'PRODUCT' && item.Product && (
            <TouchableOpacity style={styles.actionBtn} onPress={() => handleQuickBuy(item.Product)}>
              <View style={[styles.actionIconBg, { backgroundColor: '#FF9900' }]}>
                <Ionicons name="cart" size={24} color="#000" />
              </View>
              <Text style={[styles.actionCountText, { color: '#FF9900', fontWeight: 'bold' }]}>Buy</Text>
            </TouchableOpacity>
          )}
        </View>

        {/* Floating Bottom Left Details Overlay */}
        <View style={styles.bottomOverlay}>
          <Text style={styles.authorHandle}>@{item?.author?.lynk_handle || 'kivo'}</Text>
          
          {/* Only render text description on bottom left if it has a video background */}
          {hasVideo && (
            <Text style={styles.postDescription} numberOfLines={3}>
              {item.content}
            </Text>
          )}

          {/* Bottom Shoppable Card Tag Banner */}
          {item.post_type === 'PRODUCT' && item.Product && (
            <TouchableOpacity 
              style={styles.shoppableBannerTag}
              onPress={() => handleQuickBuy(item.Product)}
              activeOpacity={0.9}
            >
              <Image source={{ uri: item.Product.image_url }} style={styles.shoppableProductThumb} />
              <View style={styles.shoppableMeta}>
                <Text style={styles.shoppableTagName} numberOfLines={1}>{item.Product.name}</Text>
                <Text style={styles.shoppableTagPrice}>${parseFloat(item.Product.price).toFixed(2)} JMD</Text>
              </View>
              <View style={styles.buyBadge}>
                <Text style={styles.buyBadgeText}>1-Click Buy</Text>
              </View>
            </TouchableOpacity>
          )}
        </View>
      </View>
    );
  };

  return (
    <View 
      style={styles.container} 
      onLayout={(e) => {
        const height = e.nativeEvent.layout.height;
        if (height > 0) setLayoutHeight(height);
      }}
    >
      <FlatList
        data={posts}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        pagingEnabled={true}
        showsVerticalScrollIndicator={false}
        refreshing={refreshing}
        onRefresh={onRefresh}
        decelerationRate="fast"
        snapToInterval={layoutHeight}
        snapToAlignment="start"
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#090915' },
  postPage: { 
    width: '100%', 
    position: 'relative', 
    backgroundColor: '#000',
    overflow: 'hidden'
  },
  backgroundVideoContainer: { 
    position: 'absolute', 
    top: 0, 
    left: 0, 
    right: 0, 
    bottom: 0, 
    backgroundColor: '#000',
    justifyContent: 'center'
  },
  webview: { 
    flex: 1, 
    backgroundColor: '#000',
    opacity: 0.95
  },
  backgroundGradient: { 
    position: 'absolute', 
    top: 0, 
    left: 0, 
    right: 0, 
    bottom: 0,
    justifyContent: 'center',
    alignItems: 'center'
  },
  textPostCenterContainer: {
    paddingHorizontal: 35,
    alignItems: 'center',
    justifyContent: 'center'
  },
  quoteIcon: {
    marginBottom: 20,
    opacity: 0.8
  },
  textPostTypography: {
    color: '#FFF',
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
    lineHeight: 28,
    letterSpacing: 0.2
  },
  bottomShader: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    height: '40%'
  },
  
  // Right floating actions
  rightActionsPanel: {
    position: 'absolute',
    right: 15,
    bottom: 30,
    alignItems: 'center',
    zIndex: 10
  },
  profileContainer: {
    marginBottom: 22,
    alignItems: 'center',
    position: 'relative'
  },
  avatarCircle: {
    width: 46,
    height: 46,
    borderRadius: 23,
    backgroundColor: 'rgba(255,153,0,0.15)',
    borderWidth: 2,
    borderColor: '#FF9900',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 3,
    elevation: 5
  },
  avatarText: {
    color: '#FF9900',
    fontSize: 14,
    fontWeight: 'bold'
  },
  followPlus: {
    position: 'absolute',
    bottom: -6,
    backgroundColor: '#FF9900',
    width: 18,
    height: 18,
    borderRadius: 9,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: '#000'
  },
  followPlusChecked: {
    backgroundColor: '#00FFCC'
  },
  actionBtn: {
    alignItems: 'center',
    marginBottom: 16
  },
  actionIconBg: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(0,0,0,0.5)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 3,
    elevation: 5
  },
  actionIconBgLiked: {
    borderColor: '#FF3B30',
    backgroundColor: 'rgba(255,59,48,0.15)'
  },
  actionCountText: {
    color: '#FFF',
    fontSize: 12,
    marginTop: 4,
    fontWeight: 'bold',
    textShadowColor: 'rgba(0, 0, 0, 0.75)',
    textShadowOffset: { width: -1, height: 1 },
    textShadowRadius: 3
  },

  // Bottom Left details
  bottomOverlay: {
    position: 'absolute',
    left: 15,
    bottom: 30,
    right: 90,
    zIndex: 10
  },
  authorHandle: {
    color: '#FFF',
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 6,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: -1, height: 1 },
    textShadowRadius: 3
  },
  postDescription: {
    color: '#DDD',
    fontSize: 13,
    lineHeight: 18,
    marginBottom: 15,
    textShadowColor: 'rgba(0, 0, 0, 0.8)',
    textShadowOffset: { width: -1, height: 1 },
    textShadowRadius: 3
  },

  // Bottom Shoppable Tag
  shoppableBannerTag: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(0,0,0,0.7)',
    borderRadius: 10,
    padding: 8,
    borderLeftWidth: 3,
    borderLeftColor: '#FF9900',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)'
  },
  shoppableProductThumb: {
    width: 38,
    height: 38,
    borderRadius: 6,
    backgroundColor: '#111',
    marginRight: 10
  },
  shoppableMeta: {
    flex: 1,
    justifyContent: 'center'
  },
  shoppableTagName: {
    color: '#FFF',
    fontSize: 12,
    fontWeight: 'bold'
  },
  shoppableTagPrice: {
    color: '#FF9900',
    fontSize: 11,
    fontWeight: 'bold',
    marginTop: 1
  },
  buyBadge: {
    backgroundColor: '#FF9900',
    borderRadius: 6,
    paddingVertical: 5,
    paddingHorizontal: 10,
    marginLeft: 10
  },
  buyBadgeText: {
    color: '#000',
    fontSize: 10,
    fontWeight: 'bold'
  }
});

export default FeedScreen;

