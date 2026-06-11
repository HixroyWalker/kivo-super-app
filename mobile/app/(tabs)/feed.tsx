import React, { useState } from 'react';
import FeedScreen from '@/src/features/social/FeedScreen';

export default function FeedTab() {
  const [refreshing, setRefreshing] = useState(false);
  const [posts, setPosts] = useState([
    {
      id: 'post1',
      user_id: 'u1',
      author: { lynk_handle: 'kivo_official' },
      content: 'Welcome to the Kivo Feed! Tap the Buy button to quick-purchase items you see here.',
      post_type: 'TEXT',
      youtube_link: ''
    },
    {
      id: 'post2',
      user_id: 'u2',
      author: { lynk_handle: 'shop_ja' },
      content: 'New arrivals just landed in the store! Check them out.',
      post_type: 'PRODUCT',
      youtube_link: '',
      Product: {
        id: 'prod1',
        name: 'Kivo Snapback Hat',
        price: '2500.00',
        merchant_id: 'merchant123',
        image_url: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&w=400&q=80'
      }
    }
  ]);

  const onRefresh = () => {
    setRefreshing(true);
    setTimeout(() => setRefreshing(false), 1000);
  };

  return <FeedScreen posts={posts} refreshing={refreshing} onRefresh={onRefresh} />;
}
