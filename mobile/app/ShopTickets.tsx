import React, { useState, useEffect, useRef } from 'react';
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
  Image,
  Dimensions,
  SafeAreaView,
  Animated,
  Easing,
  PanResponder,
  ScrollView
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useCartStore } from '@/src/store/cartStore';
import { router } from 'expo-router';
import axios from 'axios';
import QRCode from 'react-native-qrcode-svg';
import { LinearGradient } from 'expo-linear-gradient';
import * as LocalAuthentication from 'expo-local-authentication';


const { width } = Dimensions.get('window');

interface Product {
  id: string;
  name: string;
  price: string;
  image_url: string;
  merchant_id: string;
}

interface EventItem {
  id: string;
  title: string;
  description: string;
  image_url: string;
  price: string;
  date: string;
  available_tickets: number;
}

const SwipeToPay = ({ amount, onComplete }: { amount: number; onComplete: () => void }) => {
  const pan = useRef(new Animated.Value(0)).current;
  const trackWidth = Dimensions.get('window').width - 80; // Margin offsets
  const handleSize = 50;
  const maxSwipe = trackWidth - handleSize - 6;

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onPanResponderMove: (_, gestureState) => {
        if (gestureState.dx > 0) {
          pan.setValue(Math.min(gestureState.dx, maxSwipe));
        }
      },
      onPanResponderRelease: (_, gestureState) => {
        if (gestureState.dx >= maxSwipe * 0.85) {
          Animated.timing(pan, {
            toValue: maxSwipe,
            duration: 100,
            useNativeDriver: true,
          }).start(() => {
            onComplete();
            Animated.timing(pan, {
              toValue: 0,
              duration: 300,
              useNativeDriver: true
            }).start();
          });
        } else {
          Animated.spring(pan, {
            toValue: 0,
            useNativeDriver: true,
          }).start();
        }
      },
    })
  ).current;

  return (
    <View style={styles.swipeTrack}>
      <Text style={styles.swipeText}>Swipe to Pay (${amount.toFixed(2)})</Text>
      <Animated.View
        {...panResponder.panHandlers}
        style={[
          styles.swipeHandle,
          { transform: [{ translateX: pan }] }
        ]}
      >
        <Ionicons name="chevron-forward-outline" size={24} color="#000" />
      </Animated.View>
    </View>
  );
};

export default function ShopTicketsScreen() {
  const [activeTab, setActiveTab] = useState<'SHOP' | 'TICKETS' | 'MY_PASSES'>('SHOP');
  const [ticketSubTab, setTicketSubTab] = useState<'EVENTS' | 'TRANSIT' | 'MY_PASSES'>('EVENTS');
  
  // Data States
  const [products, setProducts] = useState<Product[]>([]);
  const [events, setEvents] = useState<EventItem[]>([]);
  const [transitRoutes, setTransitRoutes] = useState<any[]>([]);
  const [myTickets, setMyTickets] = useState<any[]>([]);
  const [myTransitPasses, setMyTransitPasses] = useState<any[]>([]);
  
  const [loading, setLoading] = useState(true);
  const [loadingTransit, setLoadingTransit] = useState(false);
  const [loadingMyPasses, setLoadingMyPasses] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  // Amazon-inspired additions
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [expressModalVisible, setExpressModalVisible] = useState(false);
  const [expressItem, setExpressItem] = useState<any | null>(null);
  const [expressAddress, setExpressAddress] = useState('12 Ring Road, Kingston 10, Jamaica');

  // StubHub-style additions
  const [selectedGenre, setSelectedGenre] = useState<'All' | 'Concerts' | 'Sports' | 'Theater' | 'Festivals'>('All');
  const [selectedEventForTiers, setSelectedEventForTiers] = useState<EventItem | null>(null);
  const [selectedTier, setSelectedTier] = useState<'GA' | 'VIP' | 'VVIP'>('GA');
  const [ticketQuantity, setTicketQuantity] = useState(1);
  const [purchasingTicket, setPurchasingTicket] = useState(false);

  const categories = ['All', 'Tickets', 'Transit', 'Clothing', 'Electronics', 'Fashion', 'Groceries'];
  const banners = [
    { id: 'b1', title: 'Exclusive: Dubwise Carnival', subtitle: 'Grab your tickets now', image: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=800&q=80', badge: 'Popular' },
    { id: 'b2', title: 'Unity Gift transfers', subtitle: 'Zero-fee peer-to-peer transfers', image: 'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?auto=format&fit=crop&w=800&q=80', badge: 'New Feature' },
    { id: 'b3', title: 'Transit Passes online', subtitle: 'Tap to ride instantly', image: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=800&q=80', badge: 'Transit' }
  ];


  // Cart
  const { items, addItem } = useCartStore();
  const totalCartItems = items.reduce((acc, curr) => acc + curr.quantity, 0);

  // Modals
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  
  // Selected Pass Modal State
  const [selectedPass, setSelectedPass] = useState<any | null>(null);
  const [isPassModalVisible, setIsPassModalVisible] = useState(false);
  
  // Edit State
  const [selectedEventId, setSelectedEventId] = useState<string | null>(null);
  const [editPrice, setEditPrice] = useState('');
  const [editTitle, setEditTitle] = useState('');
  const [editDesc, setEditDesc] = useState('');
  const [savingEdit, setSavingEdit] = useState(false);

  // Create State
  const [createTitle, setCreateTitle] = useState('');
  const [createDesc, setCreateDesc] = useState('');
  const [createPrice, setCreatePrice] = useState('');
  const [createTicketsCount, setCreateTicketsCount] = useState('50');
  const [creatingEvent, setCreatingEvent] = useState(false);

  // Animation States
  const scannerAnim = useRef(new Animated.Value(0)).current;
  const pulseAnim = useRef(new Animated.Value(1)).current;

  // StubHub Helpers
  const calculateTierPrice = () => {
    if (!selectedEventForTiers) return 0;
    const base = parseFloat(selectedEventForTiers.price);
    if (selectedTier === 'VIP') return base * 2.0;
    if (selectedTier === 'VVIP') return base * 3.0;
    return base;
  };

  const getCalendarBadgeInfo = (dateStr: string) => {
    const d = dateStr ? new Date(dateStr) : new Date();
    const month = d.toLocaleDateString('en-US', { month: 'short' }).toUpperCase();
    const day = d.getDate().toString();
    const weekday = d.toLocaleDateString('en-US', { weekday: 'short' }).toUpperCase();
    return { month, day, weekday };
  };

  const getEventVenue = (title: string) => {
    const titleLower = title.toLowerCase();
    if (titleLower.includes('carnival') || titleLower.includes('dubwise')) return 'Sabina Park, Kingston';
    if (titleLower.includes('cup') || titleLower.includes('match') || titleLower.includes('sports')) return 'National Stadium, Kingston';
    if (titleLower.includes('comedy') || titleLower.includes('play') || titleLower.includes('theater')) return 'Ward Theatre, Kingston';
    return 'Kivo Events Hall, Kingston';
  };

  const handleBuyTicketDirect = async () => {
    if (!selectedEventForTiers) return;
    
    setPurchasingTicket(true);
    try {
      const hasHardware = await LocalAuthentication.hasHardwareAsync();
      const isEnrolled = await LocalAuthentication.isEnrolledAsync();
      let bioVerified = false;

      if (hasHardware && isEnrolled) {
        const result = await LocalAuthentication.authenticateAsync({
          promptMessage: `Authorize ticket purchase of $${(calculateTierPrice() * ticketQuantity * 1.05).toFixed(2)} JMD`,
          disableDeviceFallback: false,
        });
        bioVerified = result.success;
      } else {
        bioVerified = true;
      }

      if (!bioVerified) {
        Alert.alert('Security Block', 'Biometric confirmation required.');
        setPurchasingTicket(false);
        return;
      }

      const response = await axios.post('/api/tickets/buy', {
        event_id: selectedEventForTiers.id,
        quantity: ticketQuantity,
        tier: selectedTier
      });

      if (response.data.status === 'SUCCESS') {
        Alert.alert('Success', `Successfully purchased ${ticketQuantity} ${selectedTier} ticket(s)!`, [
          { text: 'OK', onPress: () => {
            setSelectedEventForTiers(null);
            fetchData();
            fetchMyPasses();
          }}
        ]);
      }
    } catch (error: any) {
      const errMsg = error.response?.data?.error || error.message || 'Purchase failed';
      Alert.alert('Purchase Failed', errMsg);
    } finally {
      setPurchasingTicket(false);
    }
  };

  const handleAddTierTicketToCart = () => {
    if (!selectedEventForTiers) return;
    const price = calculateTierPrice();
    addItem({
      product_id: `tkt-${selectedEventForTiers.id}-${selectedTier}`,
      name: `${selectedEventForTiers.title} - ${selectedTier} Ticket`,
      price: price,
      quantity: ticketQuantity,
      merchant_id: selectedEventForTiers.id
    });
    Alert.alert('Added to Cart', `${ticketQuantity} x ${selectedTier} Ticket for ${selectedEventForTiers.title} added to cart.`);
    setSelectedEventForTiers(null);
  };

  // Fetch Data
  const fetchData = async () => {
    setLoading(true);
    try {
      const [prodRes, eventRes] = await Promise.all([
        axios.get('/api/wallet/products'),
        axios.get('/api/tickets/events')
      ]);
      setProducts(prodRes.data);
      setEvents(eventRes.data);
    } catch (error: any) {
      console.error('Error fetching hub data:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchTransitRoutes = async () => {
    setLoadingTransit(true);
    try {
      const res = await axios.get('/api/tickets/transit');
      setTransitRoutes(res.data);
    } catch (error) {
      console.error('Error fetching transit routes:', error);
    } finally {
      setLoadingTransit(false);
    }
  };

  const fetchMyPasses = async () => {
    setLoadingMyPasses(true);
    try {
      const [ticketRes, transitRes] = await Promise.all([
        axios.get('/api/tickets/my-tickets'),
        axios.get('/api/tickets/my-transit')
      ]);
      setMyTickets(ticketRes.data);
      setMyTransitPasses(transitRes.data);
    } catch (error) {
      console.error('Error fetching my passes:', error);
    } finally {
      setLoadingMyPasses(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'SHOP') {
      fetchData();
    } else if (activeTab === 'MY_PASSES') {
      fetchMyPasses();
    } else {
      if (ticketSubTab === 'EVENTS') {
        fetchData();
      } else if (ticketSubTab === 'TRANSIT') {
        fetchTransitRoutes();
      }
    }
  }, [activeTab, ticketSubTab]);

  useEffect(() => {
    if (isPassModalVisible) {
      // Loop scanner line up and down
      scannerAnim.setValue(0);
      Animated.loop(
        Animated.sequence([
          Animated.timing(scannerAnim, {
            toValue: 1,
            duration: 2000,
            easing: Easing.linear,
            useNativeDriver: true,
          }),
          Animated.timing(scannerAnim, {
            toValue: 0,
            duration: 2000,
            easing: Easing.linear,
            useNativeDriver: true,
          }),
        ])
      ).start();

      // Pulsing outer boundary
      pulseAnim.setValue(1);
      Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, {
            toValue: 1.04,
            duration: 1000,
            easing: Easing.ease,
            useNativeDriver: true,
          }),
          Animated.timing(pulseAnim, {
            toValue: 0.96,
            duration: 1000,
            easing: Easing.ease,
            useNativeDriver: true,
          }),
        ])
      ).start();
    } else {
      scannerAnim.setValue(0);
      pulseAnim.setValue(1);
    }
  }, [isPassModalVisible]);

  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      if (activeTab === 'SHOP') {
        const prodRes = await axios.get('/api/wallet/products');
        setProducts(prodRes.data);
      } else if (activeTab === 'MY_PASSES') {
        const [ticketRes, transitRes] = await Promise.all([
          axios.get('/api/tickets/my-tickets'),
          axios.get('/api/tickets/my-transit')
        ]);
        setMyTickets(ticketRes.data);
        setMyTransitPasses(transitRes.data);
      } else {
        if (ticketSubTab === 'EVENTS') {
          const eventRes = await axios.get('/api/tickets/events');
          setEvents(eventRes.data);
        } else if (ticketSubTab === 'TRANSIT') {
          const transitRes = await axios.get('/api/tickets/transit');
          setTransitRoutes(transitRes.data);
        }
      }
    } catch (error) {
      console.error('Refresh error:', error);
    } finally {
      setRefreshing(false);
    }
  };

  // Add Product to Unified Cart
  const handleAddProductToCart = (prod: Product) => {
    addItem({
      product_id: prod.id,
      name: prod.name,
      price: parseFloat(prod.price),
      quantity: 1,
      merchant_id: prod.merchant_id
    });
    Alert.alert('Success', `${prod.name} added to cart.`);
  };

  // Add Ticket to Unified Cart
  const handleAddTicketToCart = (event: EventItem) => {
    if (event.available_tickets <= 0) {
      Alert.alert('Sold Out', 'Sorry, no tickets available for this event.');
      return;
    }
    addItem({
      product_id: `tkt-${event.id}`,
      name: `${event.title} - Ticket`,
      price: parseFloat(event.price),
      quantity: 1,
      merchant_id: event.id
    });
    Alert.alert('Added to Cart', `Ticket for ${event.title} has been added to your cart.`);
  };

  // Add Transit Route to Unified Cart
  const handleAddTransitToCart = (route: any) => {
    addItem({
      product_id: route.id,
      name: `${route.route_name} Pass`,
      price: parseFloat(route.fare),
      quantity: 1,
      merchant_id: 'Transit Authority'
    });
    Alert.alert('Added to Cart', `${route.route_name} Pass has been added to your cart.`);
  };

  // Handle viewing pass
  const handleViewPass = (pass: any) => {
    const isTicket = pass._type === 'TICKET';
    setSelectedPass({
      type: pass._type,
      name: isTicket ? pass.Event?.title || 'Event Ticket' : pass.route_name,
      token: pass.qr_token,
      extra: isTicket 
        ? `Seat/Entry Ticket ID: ${pass.id.slice(0, 8).toUpperCase()}`
        : `Pickup Code: ${pass.pickup_code || 'N/A'}`
    });
    setIsPassModalVisible(true);
  };

  // Open Edit Price Modal
  const openEditModal = (event: EventItem) => {
    setSelectedEventId(event.id);
    setEditPrice(parseFloat(event.price).toString());
    setEditTitle(event.title);
    setEditDesc(event.description);
    setIsEditModalOpen(true);
  };

  // Save Edit Price
  const saveEventEdits = async () => {
    if (!selectedEventId) return;
    if (isNaN(parseFloat(editPrice)) || parseFloat(editPrice) < 0) {
      Alert.alert('Invalid Price', 'Please enter a valid price.');
      return;
    }
    
    setSavingEdit(true);
    try {
      const res = await axios.put(`/api/tickets/events/${selectedEventId}`, {
        price: parseFloat(editPrice),
        title: editTitle,
        description: editDesc
      });
      if (res.data.status === 'SUCCESS') {
        Alert.alert('Success', 'Event updated successfully!');
        setIsEditModalOpen(false);
        fetchData();
      }
    } catch (err: any) {
      Alert.alert('Update Failed', err.response?.data?.error || 'Unknown error');
    } finally {
      setSavingEdit(false);
    }
  };

  // Create Event
  const createEvent = async () => {
    if (!createTitle.trim()) {
      Alert.alert('Title Required', 'Please enter an event title.');
      return;
    }
    if (isNaN(parseFloat(createPrice)) || parseFloat(createPrice) < 0) {
      Alert.alert('Invalid Price', 'Please enter a valid price.');
      return;
    }

    setCreatingEvent(true);
    try {
      const res = await axios.post('/api/tickets/events', {
        title: createTitle,
        description: createDesc,
        price: parseFloat(createPrice),
        ticket_count: parseInt(createTicketsCount) || 50
      });
      if (res.data.status === 'SUCCESS') {
        Alert.alert('Success', 'Event & tickets created successfully!');
        setIsCreateModalOpen(false);
        // Reset inputs
        setCreateTitle('');
        setCreateDesc('');
        setCreatePrice('');
        setCreateTicketsCount('50');
        fetchData();
      }
    } catch (err: any) {
      Alert.alert('Creation Failed', err.response?.data?.error || 'Unknown error');
    } finally {
      setCreatingEvent(false);
    }
  };

  // 1-Click Buy Now Handler
  const handleExpressCheckout = async () => {
    if (!expressItem) return;
    try {
      // 1. Perform biometric validation
      const hasHardware = await LocalAuthentication.hasHardwareAsync();
      const isEnrolled = await LocalAuthentication.isEnrolledAsync();
      let bioVerified = false;

      if (hasHardware && isEnrolled) {
        const result = await LocalAuthentication.authenticateAsync({
          promptMessage: `Authorize Purchase of $${parseFloat(expressItem.price || expressItem.fare).toFixed(2)} JMD`,
          disableDeviceFallback: false,
        });
        bioVerified = result.success;
      } else {
        bioVerified = true;
      }

      if (!bioVerified) {
        Alert.alert('Security Block', 'Biometric confirmation required.');
        return;
      }

      // 2. Submit payment with hardware binding and biometric double-lock headers
      let productId = expressItem.id;
      let itemName = expressItem.name || expressItem.title;
      let merchantId = expressItem.merchant_id || 'Unknown Merchant';
      let itemPrice = parseFloat(expressItem.price || expressItem.fare || 0);

      if (expressItem.date !== undefined) {
        // Event item
        productId = `tkt-${expressItem.id}`;
        itemName = `${expressItem.title} - Ticket`;
        merchantId = expressItem.id;
      } else if (expressItem.fare !== undefined) {
        // Transit pass
        productId = expressItem.id;
        itemName = `${expressItem.route_name} Pass`;
        merchantId = 'Transit Authority';
      }

      const response = await axios.post('/api/wallet/checkout', {
        cart_items: [{
          product_id: productId,
          name: itemName,
          price: itemPrice,
          quantity: 1,
          merchant_id: merchantId
        }],
        idempotency_key: `express-${Date.now()}`,
        shipping_address: expressAddress
      }, {
        headers: {
          'x-device-uuid': 'mock-device-uuid-12345',
          'x-biometric-auth': 'true',
          'x-biometric-timestamp': Date.now().toString()
        }
      });
      
      if (response.data.status === 'SUCCESS') {
        Alert.alert('Success', 'Order placed successfully!', [
          { text: 'OK', onPress: () => {
            setExpressModalVisible(false);
            setExpressItem(null);
            fetchData();
          }}
        ]);
      }
    } catch (error: any) {
      const errMsg = error.response?.data?.error || error.message || 'Payment failed';
      Alert.alert('Purchase Failed', errMsg);
    }
  };

  const translateY = scannerAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0, 177],
  });

  // Category Click Tab Redirection
  const handleCategoryPress = (cat: string) => {
    setSelectedCategory(cat);
    if (cat === 'Tickets') {
      setActiveTab('TICKETS');
      setTicketSubTab('EVENTS');
    } else if (cat === 'Transit') {
      setActiveTab('TICKETS');
      setTicketSubTab('TRANSIT');
    } else if (cat === 'All') {
      setActiveTab('SHOP');
    } else {
      setActiveTab('SHOP');
    }
  };

  // Filter Logic
  const filteredProducts = products.filter(item => {
    const matchesSearch = item.name.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = selectedCategory === 'All' || 
      (selectedCategory === 'Clothing' && (item.name.toLowerCase().includes('kick') || item.name.toLowerCase().includes('shoe') || item.name.toLowerCase().includes('wear') || item.name.toLowerCase().includes('tee') || item.name.toLowerCase().includes('pant') || item.name.toLowerCase().includes('prime') || item.name.toLowerCase().includes('card'))) ||
      (selectedCategory === 'Electronics' && (item.name.toLowerCase().includes('phone') || item.name.toLowerCase().includes('device') || item.name.toLowerCase().includes('auth') || item.name.toLowerCase().includes('engine'))) ||
      (selectedCategory === 'Groceries' && (item.name.toLowerCase().includes('food') || item.name.toLowerCase().includes('drink') || item.name.toLowerCase().includes('water') || item.name.toLowerCase().includes('snack')));
    return matchesSearch && matchesCategory;
  });

  const filteredEvents = events.filter(item => {
    const matchesSearch = item.title.toLowerCase().includes(searchQuery.toLowerCase()) || item.description.toLowerCase().includes(searchQuery.toLowerCase());
    if (!matchesSearch) return false;
    
    if (selectedGenre === 'All') return true;
    const titleLower = item.title.toLowerCase();
    const descLower = item.description.toLowerCase();
    if (selectedGenre === 'Concerts') {
      return titleLower.includes('concert') || titleLower.includes('music') || titleLower.includes('carnival') || titleLower.includes('dubwise') || titleLower.includes('festival') || descLower.includes('music') || descLower.includes('concert');
    }
    if (selectedGenre === 'Sports') {
      return titleLower.includes('game') || titleLower.includes('match') || titleLower.includes('cup') || titleLower.includes('sports') || titleLower.includes('race') || titleLower.includes('championship');
    }
    if (selectedGenre === 'Theater') {
      return titleLower.includes('theater') || titleLower.includes('play') || titleLower.includes('drama') || titleLower.includes('comedy') || titleLower.includes('broadway');
    }
    if (selectedGenre === 'Festivals') {
      return titleLower.includes('festival') || titleLower.includes('fest') || titleLower.includes('carnival') || titleLower.includes('expo');
    }
    return true;
  });

  const filteredTransit = transitRoutes.filter(item => {
    const matchesSearch = item.route_name.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesSearch;
  });

  return (
    <SafeAreaView style={styles.safeContainer}>
      {/* Amazon-style Search Header */}
      <View style={styles.amazonSearchHeader}>
        <TouchableOpacity style={styles.backIconButton} onPress={() => {
          if (router.canGoBack()) {
            router.back();
          } else {
            router.replace('/');
          }
        }}>
          <Ionicons name="chevron-back" size={24} color="#FFF" />
        </TouchableOpacity>
        
        <View style={styles.searchBarWrapper}>
          <Ionicons name="search" size={20} color="#888" style={styles.searchIcon} />
          <TextInput
            style={styles.searchInput}
            placeholder="Search Kivo Store, tickets, routes..."
            placeholderTextColor="#888"
            value={searchQuery}
            onChangeText={setSearchQuery}
          />
          <TouchableOpacity style={styles.scanIconButton}>
            <Ionicons name="camera-outline" size={22} color="#888" />
          </TouchableOpacity>
        </View>

        <TouchableOpacity style={styles.amazonCartButton} onPress={() => router.push('/Checkout')}>
          <Ionicons name="cart-outline" size={26} color="#FFF" />
          {totalCartItems > 0 && (
            <View style={styles.cartBadge}>
              <Text style={styles.cartBadgeText}>{totalCartItems}</Text>
            </View>
          )}
        </TouchableOpacity>
      </View>

      {/* Amazon Delivery Sub-Header */}
      <View style={styles.amazonDeliverySubHeader}>
        <Ionicons name="location-outline" size={16} color="#FFF" style={{ marginRight: 6 }} />
        <Text style={styles.deliverySubText} numberOfLines={1}>
          Deliver to John - 12 Ring Road, Kingston, Jamaica
        </Text>
      </View>

      {/* Categories ScrollView (Pills) */}
      <View style={styles.categoryScrollContainer}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.categoryPills}>
          {categories.map((cat) => (
            <TouchableOpacity
              key={cat}
              style={[
                styles.categoryPill,
                selectedCategory === cat && styles.activeCategoryPill
              ]}
              onPress={() => handleCategoryPress(cat)}
            >
              <Text
                style={[
                  styles.categoryPillText,
                  selectedCategory === cat && styles.activeCategoryPillText
                ]}
              >
                {cat}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>

      {/* Banners Carousel (Show on SHOP tab) */}
      {activeTab === 'SHOP' && searchQuery === '' && (
        <View style={styles.bannerCarouselContainer}>
          <ScrollView 
            horizontal 
            pagingEnabled 
            showsHorizontalScrollIndicator={false}
            style={styles.bannerScrollView}
            contentContainerStyle={{ height: 130 }}
          >
            {banners.map((banner) => (
              <View key={banner.id} style={styles.bannerCard}>
                <Image source={{ uri: banner.image }} style={styles.bannerImage} resizeMode="cover" />
                <LinearGradient 
                  colors={['transparent', 'rgba(0,0,0,0.85)']} 
                  style={styles.bannerGradient}
                >
                  <View style={styles.bannerBadge}>
                    <Text style={styles.bannerBadgeText}>{banner.badge}</Text>
                  </View>
                  <Text style={styles.bannerTitle}>{banner.title}</Text>
                  <Text style={styles.bannerSubtitle}>{banner.subtitle}</Text>
                </LinearGradient>
              </View>
            ))}
          </ScrollView>
        </View>
      )}

      {/* Tab Navigation */}
      <View style={styles.tabContainer}>
        <TouchableOpacity 
          style={[styles.tabButton, activeTab === 'SHOP' && styles.activeTabButton]}
          onPress={() => setActiveTab('SHOP')}
        >
          <Ionicons 
            name="bag-handle" 
            size={18} 
            color={activeTab === 'SHOP' ? '#FF9900' : '#888'} 
            style={{ marginRight: 6 }} 
          />
          <Text style={[styles.tabText, activeTab === 'SHOP' && styles.activeTabText]}>Shop Items</Text>
        </TouchableOpacity>
        <TouchableOpacity 
          style={[styles.tabButton, activeTab === 'TICKETS' && styles.activeTabButton]}
          onPress={() => {
            setActiveTab('TICKETS');
            if (ticketSubTab === 'MY_PASSES') {
              setTicketSubTab('EVENTS');
            }
          }}
        >
          <Ionicons 
            name="ticket" 
            size={18} 
            color={activeTab === 'TICKETS' ? '#FF9900' : '#888'} 
            style={{ marginRight: 6 }} 
          />
          <Text style={[styles.tabText, activeTab === 'TICKETS' && styles.activeTabText]}>Tickets & Fares</Text>
        </TouchableOpacity>
        <TouchableOpacity 
          style={[styles.tabButton, activeTab === 'MY_PASSES' && styles.activeTabButton]}
          onPress={() => {
            setActiveTab('MY_PASSES');
            setTicketSubTab('MY_PASSES');
          }}
        >
          <Ionicons 
            name="wallet" 
            size={18} 
            color={activeTab === 'MY_PASSES' ? '#FF9900' : '#888'} 
            style={{ marginRight: 6 }} 
          />
          <Text style={[styles.tabText, activeTab === 'MY_PASSES' && styles.activeTabText]}>My Passes</Text>
        </TouchableOpacity>
      </View>

      {/* Sub-segmented Ticket Selector */}
      {activeTab === 'TICKETS' && (
        <View style={styles.subTabContainer}>
          <TouchableOpacity 
            style={[styles.subTabButton, ticketSubTab === 'EVENTS' && styles.activeSubTabButton]}
            onPress={() => setTicketSubTab('EVENTS')}
          >
            <Text style={[styles.subTabText, ticketSubTab === 'EVENTS' && styles.activeSubTabText]}>Events</Text>
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.subTabButton, ticketSubTab === 'TRANSIT' && styles.activeSubTabButton]}
            onPress={() => setTicketSubTab('TRANSIT')}
          >
            <Text style={[styles.subTabText, ticketSubTab === 'TRANSIT' && styles.activeSubTabText]}>Transit Passes</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* Main List Rendering */}
      {loading && !refreshing && activeTab === 'SHOP' ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#FF9900" />
          <Text style={styles.loadingText}>Loading Marketplace...</Text>
        </View>
      ) : activeTab === 'SHOP' ? (
        <FlatList
          data={filteredProducts}
          keyExtractor={(item) => item.id}
          numColumns={2}
          contentContainerStyle={styles.listPadding}
          refreshing={refreshing}
          onRefresh={handleRefresh}
          ListEmptyComponent={
            <View style={styles.emptyState}>
              <Ionicons name="cube-outline" size={60} color="rgba(255,255,255,0.2)" />
              <Text style={styles.emptyStateTitle}>No Products Found</Text>
              <Text style={styles.emptyStateSub}>Try adjustments or searching for other items.</Text>
            </View>
          }
          renderItem={({ item }) => {
            // Stable rating and review generation from item properties
            const ratingHash = (item.id.charCodeAt(0) || 4) % 2 === 0;
            const stars = ratingHash ? 5 : 4;
            const starStr = '★'.repeat(stars) + '☆'.repeat(5 - stars);
            const reviewCount = ((item.name.length * 7) % 150) + 12;

            return (
              <View style={styles.amazonProductCard}>
                <View style={styles.amazonImageWrapper}>
                  <Image 
                    source={{ uri: item.image_url || 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=300&q=80' }} 
                    style={styles.amazonProductImage} 
                    resizeMode="cover"
                  />
                  <View style={styles.primeBadgeContainer}>
                    <Text style={styles.primeBadgeText}>Prime</Text>
                  </View>
                </View>
                <View style={styles.amazonProductDetails}>
                  <Text style={styles.amazonProductName} numberOfLines={2}>{item.name}</Text>
                  
                  {/* Amazon Stars & Reviews */}
                  <View style={styles.ratingRow}>
                    <Text style={styles.ratingStars}>{starStr}</Text>
                    <Text style={styles.reviewCount}>({reviewCount})</Text>
                  </View>

                  <Text style={styles.amazonProductPrice}>
                    <Text style={styles.currencySymbol}>$</Text>
                    {parseFloat(item.price).toFixed(2)}
                    <Text style={styles.currencyCode}> JMD</Text>
                  </Text>
                  
                  <Text style={styles.deliveryInfoText}>FREE Delivery Tomorrow</Text>

                  {/* Amazon Style Action Buttons */}
                  <TouchableOpacity 
                    style={styles.amazonAddCartButton}
                    onPress={() => handleAddProductToCart(item)}
                  >
                    <Text style={styles.amazonAddCartButtonText}>Add to Cart</Text>
                  </TouchableOpacity>

                  <TouchableOpacity 
                    style={styles.amazonBuyNowButton}
                    onPress={() => {
                      setExpressItem(item);
                      setExpressModalVisible(true);
                    }}
                  >
                    <Text style={styles.amazonBuyNowButtonText}>Buy Now</Text>
                  </TouchableOpacity>
                </View>
              </View>
            );
          }}
        />
      ) : activeTab === 'MY_PASSES' ? (
        <View style={{ flex: 1 }}>
          <View style={styles.actionHeaderRow}>
            <Text style={styles.sectionHeading}>My Purchased Passes</Text>
          </View>
          {loadingMyPasses && !refreshing ? (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="small" color="#6C63FF" />
              <Text style={styles.loadingText}>Loading your passes...</Text>
            </View>
          ) : (
            <FlatList
              data={[
                ...myTickets.map(t => ({ ...t, _type: 'TICKET' })),
                ...myTransitPasses.map(t => ({ ...t, _type: 'TRANSIT' }))
              ]}
              keyExtractor={(item, index) => item.id || item.qr_token || index.toString()}
              contentContainerStyle={styles.listPadding}
              refreshing={refreshing}
              onRefresh={handleRefresh}
              ListEmptyComponent={
                <View style={styles.emptyState}>
                  <Ionicons name="wallet-outline" size={60} color="rgba(255,255,255,0.2)" />
                  <Text style={styles.emptyStateTitle}>No Purchased Passes</Text>
                  <Text style={styles.emptyStateSub}>Your tickets and transit passes will appear here after purchase.</Text>
                </View>
              }
              renderItem={({ item }) => {
                const isTicket = item._type === 'TICKET';
                const name = isTicket ? item.Event?.title || 'Event Ticket' : item.route_name;
                const dateStr = isTicket 
                  ? (item.Event?.date ? new Date(item.Event.date).toLocaleDateString() : 'Active')
                  : (item.purchased_at ? new Date(item.purchased_at).toLocaleDateString() : 'Active');
                const price = isTicket ? item.price : item.price;
                
                return (
                  <TouchableOpacity 
                    style={styles.myPassCard}
                    onPress={() => handleViewPass(item)}
                    activeOpacity={0.8}
                  >
                    <View style={styles.myPassLeft}>
                      <View style={[styles.myPassIconBg, { backgroundColor: isTicket ? 'rgba(108,99,255,0.15)' : 'rgba(255,153,0,0.15)' }]}>
                        <Ionicons 
                          name={isTicket ? "ticket-outline" : "bus-outline"} 
                          size={24} 
                          color={isTicket ? "#6C63FF" : "#FF9900"} 
                        />
                      </View>
                      <View style={styles.myPassDetails}>
                        <Text style={styles.myPassTitle} numberOfLines={1}>{name}</Text>
                        <Text style={styles.myPassSubtitle}>
                          {isTicket ? 'Event Pass' : 'Transit Pass'} • {dateStr}
                        </Text>
                        <Text style={styles.myPassPrice}>${parseFloat(price).toFixed(2)} JMD</Text>
                      </View>
                    </View>
                    
                    <View style={styles.myPassRight}>
                      <View style={styles.tapToRideBadge}>
                        <Ionicons name="phone-portrait-outline" size={12} color="#FF9900" style={{ marginRight: 3 }} />
                        <Text style={styles.tapToRideText}>Tap to Ride</Text>
                      </View>
                    </View>
                  </TouchableOpacity>
                );
              }}
            />
          )}
        </View>
      ) : (
        <View style={{ flex: 1 }}>
          {ticketSubTab === 'EVENTS' ? (
            <View style={{ flex: 1 }}>
              {/* Quick Creator Bar */}
              <View style={styles.actionHeaderRow}>
                <Text style={styles.sectionHeading}>Active Events</Text>
                <TouchableOpacity 
                  style={styles.createEventHeaderBtn}
                  onPress={() => setIsCreateModalOpen(true)}
                >
                  <Ionicons name="add" size={16} color="#FF9900" />
                  <Text style={styles.createEventHeaderBtnText}>Create Event</Text>
                </TouchableOpacity>
              </View>

              {/* StubHub Genre Filters */}
              <View style={styles.stubHubGenreContainer}>
                <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.genrePills}>
                  {(['All', 'Concerts', 'Sports', 'Theater', 'Festivals'] as const).map((genre) => (
                    <TouchableOpacity
                      key={genre}
                      style={[
                        styles.stubHubGenrePill,
                        selectedGenre === genre && styles.activeStubHubGenrePill
                      ]}
                      onPress={() => setSelectedGenre(genre)}
                    >
                      <Text
                        style={[
                          styles.stubHubGenrePillText,
                          selectedGenre === genre && styles.activeStubHubGenrePillText
                        ]}
                      >
                        {genre === 'All' ? 'All Events' : genre}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              </View>
              
              <FlatList
                data={filteredEvents}
                keyExtractor={(item) => item.id}
                contentContainerStyle={styles.listPadding}
                refreshing={refreshing}
                onRefresh={handleRefresh}
                ListEmptyComponent={
                  <View style={styles.emptyState}>
                    <Ionicons name="ticket-outline" size={60} color="rgba(255,255,255,0.2)" />
                    <Text style={styles.emptyStateTitle}>No Active Tickets</Text>
                    <Text style={styles.emptyStateSub}>Create an event or search other keywords.</Text>
                  </View>
                }
                renderItem={({ item }) => {
                  const { month, day, weekday } = getCalendarBadgeInfo(item.date);
                  const venue = getEventVenue(item.title);
                  
                  // Urgency levels
                  let urgencyText = '';
                  let urgencyStyle = null;
                  if (item.available_tickets === 0) {
                    urgencyText = 'Sold Out';
                    urgencyStyle = styles.urgencySoldOut;
                  } else if (item.available_tickets <= 5) {
                    urgencyText = `🔥 Only ${item.available_tickets} left!`;
                    urgencyStyle = styles.urgencyCritical;
                  } else if (item.available_tickets <= 15) {
                    urgencyText = '⚡ Selling Fast!';
                    urgencyStyle = styles.urgencyHigh;
                  } else {
                    urgencyText = '✨ Popular Event';
                    urgencyStyle = styles.urgencyNormal;
                  }

                  return (
                    <View style={styles.stubHubEventCard}>
                      {/* Left: Date Badge */}
                      <View style={styles.stubHubDateBadge}>
                        <View style={styles.stubHubMonthBg}>
                          <Text style={styles.stubHubMonthText}>{month}</Text>
                        </View>
                        <View style={styles.stubHubDayBg}>
                          <Text style={styles.stubHubDayText}>{day}</Text>
                          <Text style={styles.stubHubWeekdayText}>{weekday}</Text>
                        </View>
                      </View>

                      {/* Middle: Details */}
                      <View style={styles.stubHubDetailsCol}>
                        <Text style={styles.stubHubEventTitle} numberOfLines={1}>{item.title}</Text>
                        <Text style={styles.stubHubEventVenue} numberOfLines={1}>
                          <Ionicons name="location-sharp" size={11} color="#888" style={{ marginRight: 2 }} />
                          {venue}
                        </Text>
                        
                        {urgencyText ? (
                          <View style={[styles.stubHubUrgencyBadge, urgencyStyle]}>
                            <Text style={[styles.stubHubUrgencyText, urgencyStyle && { color: urgencyStyle.color }]}>{urgencyText}</Text>
                          </View>
                        ) : null}
                      </View>

                      {/* Right: Price & Button */}
                      <View style={styles.stubHubActionCol}>
                        <Text style={styles.stubHubPriceLabel}>From</Text>
                        <Text style={styles.stubHubPriceText}>${parseFloat(item.price).toFixed(2)}</Text>
                        <Text style={styles.stubHubJmdText}>JMD</Text>

                        <TouchableOpacity 
                          style={[styles.stubHubSeeTicketsBtn, item.available_tickets <= 0 && styles.disabledSeeBtn]}
                          onPress={() => {
                            setSelectedEventForTiers(item);
                            setSelectedTier('GA');
                            setTicketQuantity(1);
                          }}
                          disabled={item.available_tickets <= 0}
                        >
                          <Text style={styles.stubHubSeeTicketsText}>See Tickets</Text>
                        </TouchableOpacity>

                        <TouchableOpacity 
                          style={styles.stubHubEditEventBtn}
                          onPress={() => openEditModal(item)}
                        >
                          <Text style={styles.stubHubEditEventText}>Edit</Text>
                        </TouchableOpacity>
                      </View>
                    </View>
                  );
                }}
              />
            </View>
          ) : (
            <View style={{ flex: 1 }}>
              <View style={styles.actionHeaderRow}>
                <Text style={styles.sectionHeading}>Available Routes</Text>
              </View>
              {loadingTransit && !refreshing ? (
                <View style={styles.loadingContainer}>
                  <ActivityIndicator size="small" color="#FF9900" />
                  <Text style={styles.loadingText}>Fetching transit routes...</Text>
                </View>
              ) : (
                <FlatList
                  data={filteredTransit}
                  keyExtractor={(item) => item.id}
                  contentContainerStyle={styles.listPadding}
                  refreshing={refreshing}
                  onRefresh={handleRefresh}
                  ListEmptyComponent={
                    <View style={styles.emptyState}>
                      <Ionicons name="bus-outline" size={60} color="rgba(255,255,255,0.2)" />
                      <Text style={styles.emptyStateTitle}>No Routes Found</Text>
                      <Text style={styles.emptyStateSub}>Transit fares will display here.</Text>
                    </View>
                  }
                  renderItem={({ item }) => (
                    <View style={styles.transitCard}>
                      <View style={styles.transitLeft}>
                        <View style={styles.transitIconContainer}>
                          <Ionicons name="bus" size={26} color="#FF9900" />
                        </View>
                        <View style={styles.transitMeta}>
                          <Text style={styles.transitTitle}>{item.route_name}</Text>
                          <Text style={styles.transitSub}>Transit Pass | Direct Route</Text>
                          <Text style={styles.transitPrice}>${parseFloat(item.fare).toFixed(2)} JMD</Text>
                        </View>
                      </View>
                      
                      <View style={styles.transitRight}>
                        <TouchableOpacity 
                          style={styles.transitBuyNowBtn}
                          onPress={() => {
                            setExpressItem(item);
                            setExpressModalVisible(true);
                          }}
                        >
                          <Text style={styles.transitBuyNowBtnText}>Buy Now</Text>
                        </TouchableOpacity>

                        <TouchableOpacity 
                          style={styles.transitCartBtn}
                          onPress={() => handleAddTransitToCart(item)}
                        >
                          <Ionicons name="cart-outline" size={16} color="#FFF" />
                        </TouchableOpacity>
                      </View>
                    </View>
                  )}
                />
              )}
            </View>
          )}
        </View>
      )}

      {/* Express Buy Now Bottom Sheet Modal */}
      <Modal
        visible={expressModalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => {
          setExpressModalVisible(false);
          setExpressItem(null);
        }}
      >
        <View style={styles.expressModalBg}>
          <TouchableOpacity 
            style={styles.expressModalDismissArea} 
            activeOpacity={1} 
            onPress={() => {
              setExpressModalVisible(false);
              setExpressItem(null);
            }} 
          />
          <View style={styles.expressSheetContent}>
            <View style={styles.sheetGrabber} />

            <View style={styles.expressHeader}>
              <Text style={styles.expressTitle}>Buy Now - Express Checkout</Text>
              <TouchableOpacity 
                style={styles.expressCloseBtn}
                onPress={() => {
                  setExpressModalVisible(false);
                  setExpressItem(null);
                }}
              >
                <Ionicons name="close" size={24} color="#FFF" />
              </TouchableOpacity>
            </View>

            {expressItem && (
              <ScrollView style={styles.expressItemScroll} contentContainerStyle={{ paddingBottom: 30 }}>
                <View style={styles.expressItemRow}>
                  <Image 
                    source={{ uri: expressItem.image_url || expressItem.image || 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=300&q=80' }} 
                    style={styles.expressItemImage} 
                    resizeMode="cover"
                  />
                  <View style={styles.expressItemMeta}>
                    <Text style={styles.expressItemName} numberOfLines={2}>
                      {expressItem.name || expressItem.title || expressItem.route_name}
                    </Text>
                    <Text style={styles.expressItemMerchant}>
                      Sold by: {expressItem.merchant_id || (expressItem.fare !== undefined ? 'Transit Authority' : 'Kivo Hub')}
                    </Text>
                    <Text style={styles.expressItemPrice}>
                      ${parseFloat(expressItem.price || expressItem.fare).toFixed(2)} JMD
                    </Text>
                  </View>
                </View>

                {/* Delivery Information */}
                <View style={styles.expressSection}>
                  <Text style={styles.expressSectionTitle}>Shipping Address</Text>
                  <TextInput
                    style={styles.expressAddressInput}
                    value={expressAddress}
                    onChangeText={expressAddress => setExpressAddress(expressAddress)}
                    placeholder="Enter delivery address"
                    placeholderTextColor="#555"
                    multiline
                  />
                </View>

                {/* Account Balances and Details */}
                <View style={styles.expressSection}>
                  <View style={styles.balanceRow}>
                    <Text style={styles.balanceLabel}>Available Balance</Text>
                    <Text style={styles.balanceValue}>$125,430.00 JMD</Text>
                  </View>
                  <View style={styles.balanceRow}>
                    <Text style={styles.balanceLabel}>Shipping Speed</Text>
                    <Text style={[styles.balanceValue, { color: '#FF9900' }]}>Instant / Pickup (FREE)</Text>
                  </View>
                </View>

                {/* Swipe Slider Component */}
                <SwipeToPay 
                  amount={parseFloat(expressItem.price || expressItem.fare)}
                  onComplete={handleExpressCheckout}
                />
                
                <Text style={styles.expressSecurityFooter}>
                  🔒 Double-Locked with Biometrics & Google Play Integrity
                </Text>
              </ScrollView>
            )}
          </View>
        </View>
      </Modal>

      {/* Tap to Ride Pulsing QR Pass Modal */}
      <Modal visible={isPassModalVisible} transparent animationType="fade">
        <View style={styles.modalBg}>
          <View style={styles.passModalContent}>
            {/* Elegant Header */}
            <View style={styles.passModalHeader}>
              <View style={styles.passHeaderIconBg}>
                <Ionicons 
                  name={selectedPass?.type === 'TICKET' ? 'ticket-outline' : 'bus-outline'} 
                  size={20} 
                  color={selectedPass?.type === 'TICKET' ? '#6C63FF' : '#FF9900'} 
                />
              </View>
              <Text style={styles.passModalTitle} numberOfLines={1}>
                {selectedPass?.type === 'TICKET' ? 'EVENT PASS' : 'TRANSIT TICKET'}
              </Text>
              <TouchableOpacity onPress={() => setIsPassModalVisible(false)} style={styles.passCloseBtn}>
                <Ionicons name="close" size={20} color="#FFF" />
              </TouchableOpacity>
            </View>

            {/* Ticket Info */}
            <Text style={styles.passNameText}>{selectedPass?.name}</Text>
            <Text style={styles.passExtraText}>{selectedPass?.extra}</Text>

            {/* Pulsing QR Scanner Container */}
            <View style={styles.qrPulseOuter}>
              <Animated.View style={[
                styles.qrPulseContainer, 
                { transform: [{ scale: pulseAnim }] }
              ]}>
                <View style={styles.qrPassWrapper}>
                  {selectedPass?.token && (
                    <QRCode 
                      value={selectedPass.token} 
                      size={180} 
                      color="#000" 
                      backgroundColor="#FFF" 
                    />
                  )}
                  {/* Animated Scanner Line */}
                  <Animated.View style={[
                    styles.scannerLine, 
                    { transform: [{ translateY }] }
                  ]} />
                </View>
              </Animated.View>
            </View>

            {/* tap to scan notification */}
            <View style={styles.tapPromptContainer}>
              <Ionicons name="wifi" size={18} color="#FF9900" style={styles.wifiIcon} />
              <Text style={styles.tapPromptText}>Hold near KIVO validator terminal</Text>
            </View>

            {/* Close button */}
            <TouchableOpacity 
              style={styles.passSubmitBtn}
              onPress={() => setIsPassModalVisible(false)}
            >
              <Text style={styles.passSubmitBtnText}>Done</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Edit Ticket Price Modal */}
      <Modal visible={isEditModalOpen} transparent animationType="fade">
        <View style={styles.modalBg}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Edit Event Details</Text>
              <TouchableOpacity onPress={() => setIsEditModalOpen(false)}>
                <Ionicons name="close-circle" size={26} color="#FFF" />
              </TouchableOpacity>
            </View>

            <Text style={styles.inputLabel}>Event Title</Text>
            <TextInput
              style={styles.modalInput}
              value={editTitle}
              onChangeText={setEditTitle}
              placeholder="Event Title"
              placeholderTextColor="#555"
            />

            <Text style={styles.inputLabel}>Description</Text>
            <TextInput
              style={[styles.modalInput, { height: 60 }]}
              value={editDesc}
              onChangeText={setEditDesc}
              placeholder="Event description"
              placeholderTextColor="#555"
              multiline
            />

            <Text style={styles.inputLabel}>Price (JMD)</Text>
            <TextInput
              style={styles.modalInput}
              value={editPrice}
              onChangeText={setEditPrice}
              keyboardType="decimal-pad"
              placeholder="0.00"
              placeholderTextColor="#555"
            />

            <TouchableOpacity 
              style={[styles.modalSubmitBtn, savingEdit && styles.disabledBtn]}
              onPress={saveEventEdits}
              disabled={savingEdit}
            >
              {savingEdit ? (
                <ActivityIndicator size="small" color="#FFF" />
              ) : (
                <Text style={styles.modalSubmitBtnText}>Save Changes</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Create Ticket & Event Modal */}
      <Modal visible={isCreateModalOpen} transparent animationType="slide">
        <View style={styles.modalBg}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Host New Event</Text>
              <TouchableOpacity onPress={() => setIsCreateModalOpen(false)}>
                <Ionicons name="close-circle" size={26} color="#FFF" />
              </TouchableOpacity>
            </View>

            <Text style={styles.inputLabel}>Event Title</Text>
            <TextInput
              style={styles.modalInput}
              value={createTitle}
              onChangeText={setCreateTitle}
              placeholder="e.g. Dubwise Carnival 2026"
              placeholderTextColor="#555"
            />

            <Text style={styles.inputLabel}>Description</Text>
            <TextInput
              style={[styles.modalInput, { height: 60 }]}
              value={createDesc}
              onChangeText={setCreateDesc}
              placeholder="Details about the venue, time, etc."
              placeholderTextColor="#555"
              multiline
            />

            <View style={styles.inputRow}>
              <View style={{ flex: 1, marginRight: 10 }}>
                <Text style={styles.inputLabel}>Price (JMD)</Text>
                <TextInput
                  style={styles.modalInput}
                  value={createPrice}
                  onChangeText={setCreatePrice}
                  keyboardType="decimal-pad"
                  placeholder="0.00"
                  placeholderTextColor="#555"
                />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={styles.inputLabel}>Ticket Limit</Text>
                <TextInput
                  style={styles.modalInput}
                  value={createTicketsCount}
                  onChangeText={setCreateTicketsCount}
                  keyboardType="number-pad"
                  placeholder="50"
                  placeholderTextColor="#555"
                />
              </View>
            </View>

            <TouchableOpacity 
              style={[styles.modalSubmitBtn, creatingEvent && styles.disabledBtn]}
              onPress={createEvent}
              disabled={creatingEvent}
            >
              {creatingEvent ? (
                <ActivityIndicator size="small" color="#FFF" />
              ) : (
                <Text style={styles.modalSubmitBtnText}>Create Event</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* StubHub Seating Zone Selector Bottom Sheet */}
      <Modal
        visible={selectedEventForTiers !== null}
        transparent
        animationType="slide"
        onRequestClose={() => setSelectedEventForTiers(null)}
      >
        <View style={styles.expressModalBg}>
          <TouchableOpacity 
            style={styles.expressModalDismissArea} 
            activeOpacity={1} 
            onPress={() => setSelectedEventForTiers(null)} 
          />
          <View style={styles.stubHubZoneSheet}>
            <View style={styles.sheetGrabber} />

            {selectedEventForTiers && (
              <View style={{ flex: 1 }}>
                {/* Header */}
                <View style={styles.stubHubZoneHeader}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.stubHubZoneSheetTitle} numberOfLines={1}>{selectedEventForTiers.title}</Text>
                    <Text style={styles.stubHubZoneSheetVenue}>
                      {getEventVenue(selectedEventForTiers.title)} • {new Date(selectedEventForTiers.date).toLocaleDateString()}
                    </Text>
                  </View>
                  <TouchableOpacity 
                    style={styles.expressCloseBtn}
                    onPress={() => setSelectedEventForTiers(null)}
                  >
                    <Ionicons name="close" size={22} color="#FFF" />
                  </TouchableOpacity>
                </View>

                {/* Seating Map Visual Representation */}
                <View style={styles.stubHubMapContainer}>
                  {/* Stage */}
                  <View style={styles.stubHubStage}>
                    <Text style={styles.stubHubStageText}>🎤 STAGE 🎸</Text>
                  </View>
                  
                  {/* Seating Sections Row */}
                  <View style={styles.stubHubSectionsRow}>
                    {/* VVIP */}
                    <TouchableOpacity 
                      style={[
                        styles.stubHubSectionBox, 
                        styles.sectionBoxVvip,
                        selectedTier === 'VVIP' && styles.sectionBoxSelected
                      ]}
                      onPress={() => {
                        setSelectedTier('VVIP');
                        setTicketQuantity(1);
                      }}
                    >
                      <Text style={styles.sectionBoxLabel}>VVIP</Text>
                      <Text style={styles.sectionBoxPrice}>3.0x</Text>
                    </TouchableOpacity>

                    {/* VIP */}
                    <TouchableOpacity 
                      style={[
                        styles.stubHubSectionBox, 
                        styles.sectionBoxVip,
                        selectedTier === 'VIP' && styles.sectionBoxSelected
                      ]}
                      onPress={() => {
                        setSelectedTier('VIP');
                        setTicketQuantity(1);
                      }}
                    >
                      <Text style={styles.sectionBoxLabel}>VIP</Text>
                      <Text style={styles.sectionBoxPrice}>2.0x</Text>
                    </TouchableOpacity>

                    {/* GA */}
                    <TouchableOpacity 
                      style={[
                        styles.stubHubSectionBox, 
                        styles.sectionBoxGa,
                        selectedTier === 'GA' && styles.sectionBoxSelected
                      ]}
                      onPress={() => {
                        setSelectedTier('GA');
                        setTicketQuantity(1);
                      }}
                    >
                      <Text style={styles.sectionBoxLabel}>GA</Text>
                      <Text style={styles.sectionBoxPrice}>1.0x</Text>
                    </TouchableOpacity>
                  </View>
                  <Text style={styles.mapHintText}>Tap a section on the map to switch zones</Text>
                </View>

                {/* Tier Details list under map */}
                <ScrollView style={{ flex: 1 }} contentContainerStyle={{ paddingBottom: 20 }}>
                  <View style={styles.tierSelectorContainer}>
                    <Text style={styles.selectTierHeading}>Select Ticket Tier</Text>
                    
                    {/* GA Tier Row */}
                    <TouchableOpacity 
                      style={[styles.tierRowOption, selectedTier === 'GA' && styles.tierRowOptionActive]}
                      onPress={() => {
                        setSelectedTier('GA');
                        setTicketQuantity(1);
                      }}
                    >
                      <View style={[styles.tierColorIndicator, { backgroundColor: '#10B981' }]} />
                      <View style={{ flex: 1 }}>
                        <Text style={styles.tierRowTitle}>General Admission (GA)</Text>
                        <Text style={styles.tierRowRowInfo}>Section GA Lawn • Access to main grounds</Text>
                      </View>
                      <Text style={styles.tierRowPrice}>${parseFloat(selectedEventForTiers.price).toFixed(0)} JMD</Text>
                    </TouchableOpacity>

                    {/* VIP Tier Row */}
                    <TouchableOpacity 
                      style={[styles.tierRowOption, selectedTier === 'VIP' && styles.tierRowOptionActive]}
                      onPress={() => {
                        setSelectedTier('VIP');
                        setTicketQuantity(1);
                      }}
                    >
                      <View style={[styles.tierColorIndicator, { backgroundColor: '#3B82F6' }]} />
                      <View style={{ flex: 1 }}>
                        <Text style={styles.tierRowTitle}>VIP Section</Text>
                        <Text style={styles.tierRowRowInfo}>Section VIP Center • Elevated platform, 1 drink free</Text>
                      </View>
                      <Text style={styles.tierRowPrice}>${(parseFloat(selectedEventForTiers.price) * 2).toFixed(0)} JMD</Text>
                    </TouchableOpacity>

                    {/* VVIP Tier Row */}
                    <TouchableOpacity 
                      style={[styles.tierRowOption, selectedTier === 'VVIP' && styles.tierRowOptionActive]}
                      onPress={() => {
                        setSelectedTier('VVIP');
                        setTicketQuantity(1);
                      }}
                    >
                      <View style={[styles.tierColorIndicator, { backgroundColor: '#F59E0B' }]} />
                      <View style={{ flex: 1 }}>
                        <Text style={styles.tierRowTitle}>VVIP Front Row</Text>
                        <Text style={styles.tierRowRowInfo}>Section VVIP Box • Front row seat, VIP catering</Text>
                      </View>
                      <Text style={styles.tierRowPrice}>${(parseFloat(selectedEventForTiers.price) * 3).toFixed(0)} JMD</Text>
                    </TouchableOpacity>
                  </View>

                  {/* Quantity and Pricing Summary */}
                  <View style={styles.pricingSummarySection}>
                    <View style={styles.qtyContainerRow}>
                      <Text style={styles.qtyLabel}>Quantity:</Text>
                      <View style={styles.qtyControlBlock}>
                        <TouchableOpacity 
                          style={styles.qtyButton}
                          onPress={() => ticketQuantity > 1 && setTicketQuantity(ticketQuantity - 1)}
                        >
                          <Ionicons name="remove" size={16} color="#FFF" />
                        </TouchableOpacity>
                        <Text style={styles.qtyValue}>{ticketQuantity}</Text>
                        <TouchableOpacity 
                          style={styles.qtyButton}
                          onPress={() => {
                            if (ticketQuantity < (selectedEventForTiers.available_tickets || 5)) {
                              setTicketQuantity(ticketQuantity + 1);
                            } else {
                              Alert.alert('Limit Reached', 'Cannot exceed available ticket quantity.');
                            }
                          }}
                        >
                          <Ionicons name="add" size={16} color="#FFF" />
                        </TouchableOpacity>
                      </View>
                    </View>

                    {/* Cost Breakout */}
                    <View style={styles.breakoutBlock}>
                      <View style={styles.breakoutRow}>
                        <Text style={styles.breakoutLabel}>
                          {selectedTier} Ticket ({ticketQuantity}x)
                        </Text>
                        <Text style={styles.breakoutValue}>
                          ${(calculateTierPrice() * ticketQuantity).toFixed(2)} JMD
                        </Text>
                      </View>
                      <View style={styles.breakoutRow}>
                        <Text style={styles.breakoutLabel}>Service Fee (5%)</Text>
                        <Text style={styles.breakoutValue}>
                          ${(calculateTierPrice() * ticketQuantity * 0.05).toFixed(2)} JMD
                        </Text>
                      </View>
                      <View style={[styles.breakoutRow, styles.breakoutTotalRow]}>
                        <Text style={styles.totalPriceLabel}>Total Amount</Text>
                        <Text style={styles.totalPriceValue}>
                          ${(calculateTierPrice() * ticketQuantity * 1.05).toFixed(2)} JMD
                        </Text>
                      </View>
                    </View>
                  </View>

                  {/* Interactive Swipe to Pay */}
                  {purchasingTicket ? (
                    <ActivityIndicator size="large" color="#FF9900" style={{ marginVertical: 20 }} />
                  ) : (
                    <View style={{ paddingHorizontal: 5 }}>
                      <SwipeToPay 
                        amount={calculateTierPrice() * ticketQuantity * 1.05}
                        onComplete={handleBuyTicketDirect}
                      />
                      
                      {/* Standard Cart add fallback */}
                      <TouchableOpacity 
                        style={styles.stubHubAddCartFallback}
                        onPress={handleAddTierTicketToCart}
                      >
                        <Text style={styles.stubHubAddCartFallbackText}>Add {selectedTier} Tickets to Cart</Text>
                      </TouchableOpacity>
                    </View>
                  )}
                  
                  <Text style={styles.expressSecurityFooter}>
                    🔒 Secured double-locked payments powered by KIVO
                  </Text>
                </ScrollView>
              </View>
            )}
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}


const styles = StyleSheet.create({
  safeContainer: { flex: 1, backgroundColor: '#090915' },
  
  // Amazon Search Header
  amazonSearchHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 15,
    paddingTop: 15,
    paddingBottom: 10,
    backgroundColor: '#090915',
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.05)'
  },
  backIconButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255,255,255,0.05)',
    justifyContent: 'center',
    alignItems: 'center'
  },
  searchBarWrapper: {
    flex: 1,
    height: 40,
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 20,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    marginHorizontal: 10
  },
  searchIcon: { marginRight: 6 },
  searchInput: {
    flex: 1,
    color: '#FFF',
    fontSize: 14,
    height: '100%',
    paddingVertical: 0
  },
  scanIconButton: { padding: 4 },
  amazonCartButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255,255,255,0.05)',
    justifyContent: 'center',
    alignItems: 'center'
  },
  cartBadge: {
    position: 'absolute',
    top: 2,
    right: 2,
    backgroundColor: '#FF9900',
    borderRadius: 9,
    width: 18,
    height: 18,
    justifyContent: 'center',
    alignItems: 'center'
  },
  cartBadgeText: { color: '#000', fontSize: 10, fontWeight: 'bold' },

  // Delivery Sub-header
  amazonDeliverySubHeader: {
    backgroundColor: '#131326',
    paddingVertical: 8,
    paddingHorizontal: 15,
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.03)'
  },
  deliverySubText: { color: 'rgba(255,255,255,0.85)', fontSize: 12, fontWeight: '500' },

  // Categories scroll
  categoryScrollContainer: {
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.05)'
  },
  categoryPills: { paddingHorizontal: 15 },
  categoryPill: {
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: 15,
    backgroundColor: 'rgba(255,255,255,0.04)',
    marginRight: 8,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.06)'
  },
  activeCategoryPill: {
    backgroundColor: 'rgba(255, 153, 0, 0.12)',
    borderColor: '#FF9900'
  },
  categoryPillText: { color: '#888', fontSize: 12, fontWeight: 'bold' },
  activeCategoryPillText: { color: '#FF9900' },

  // Banner Carousel
  bannerCarouselContainer: {
    marginVertical: 12,
    paddingHorizontal: 15
  },
  bannerScrollView: { height: 130, borderRadius: 12, overflow: 'hidden' },
  bannerCard: {
    width: Dimensions.get('window').width - 30,
    height: 130,
    position: 'relative',
    borderRadius: 12,
    overflow: 'hidden',
    marginRight: 10
  },
  bannerImage: { width: '100%', height: '100%' },
  bannerGradient: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    top: 0,
    justifyContent: 'flex-end',
    padding: 12
  },
  bannerBadge: {
    backgroundColor: '#FF9900',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    alignSelf: 'flex-start',
    marginBottom: 4
  },
  bannerBadgeText: { color: '#000', fontSize: 9, fontWeight: 'bold' },
  bannerTitle: { color: '#FFF', fontSize: 15, fontWeight: 'bold' },
  bannerSubtitle: { color: '#BBB', fontSize: 11, marginTop: 1 },

  // Tabs
  tabContainer: { 
    flexDirection: 'row', 
    backgroundColor: 'rgba(255,255,255,0.03)', 
    borderRadius: 12, 
    marginHorizontal: 15, 
    padding: 4, 
    marginVertical: 12,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)'
  },
  tabButton: { 
    flex: 1, 
    flexDirection: 'row', 
    alignItems: 'center', 
    justifyContent: 'center', 
    paddingVertical: 10, 
    borderRadius: 8 
  },
  activeTabButton: { backgroundColor: 'rgba(255, 153, 0, 0.1)' },
  tabText: { color: '#888', fontSize: 13, fontWeight: 'bold' },
  activeTabText: { color: '#FF9900' },

  // Amazon Product Card Grid
  amazonProductCard: { 
    flex: 0.5, 
    backgroundColor: 'rgba(255,255,255,0.03)', 
    borderRadius: 12, 
    margin: 5, 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.05)',
    overflow: 'hidden'
  },
  amazonImageWrapper: { position: 'relative', width: '100%', height: 110, backgroundColor: '#111' },
  amazonProductImage: { width: '100%', height: '100%' },
  primeBadgeContainer: {
    position: 'absolute',
    top: 6,
    left: 6,
    backgroundColor: '#00A8E8',
    paddingHorizontal: 5,
    paddingVertical: 1,
    borderRadius: 3
  },
  primeBadgeText: { color: '#FFF', fontSize: 8, fontWeight: 'bold' },
  amazonProductDetails: { padding: 10 },
  amazonProductName: { color: '#FFF', fontSize: 12, height: 34, lineHeight: 17 },
  ratingRow: { flexDirection: 'row', alignItems: 'center', marginVertical: 3 },
  ratingStars: { color: '#FF9900', fontSize: 11, marginRight: 3 },
  reviewCount: { color: '#666', fontSize: 10 },
  amazonProductPrice: { color: '#FFF', fontSize: 15, fontWeight: 'bold', marginVertical: 2 },
  currencySymbol: { color: '#FFF', fontSize: 11, fontWeight: 'normal' },
  currencyCode: { color: '#FF9900', fontSize: 10, fontWeight: 'bold' },
  deliveryInfoText: { color: '#00FFCC', fontSize: 10, marginVertical: 1 },
  amazonAddCartButton: { 
    backgroundColor: 'rgba(255, 153, 0, 0.1)', 
    borderWidth: 1,
    borderColor: '#FFAD33',
    borderRadius: 8, 
    paddingVertical: 6, 
    justifyContent: 'center', 
    alignItems: 'center',
    marginTop: 8
  },
  amazonAddCartButtonText: { color: '#FFAD33', fontSize: 10, fontWeight: 'bold' },
  amazonBuyNowButton: { 
    backgroundColor: '#FF9900', 
    borderRadius: 8, 
    paddingVertical: 7, 
    justifyContent: 'center', 
    alignItems: 'center',
    marginTop: 5
  },
  amazonBuyNowButtonText: { color: '#000', fontSize: 10, fontWeight: 'bold' },

  // Event & Ticket Layout
  actionHeaderRow: { 
    flexDirection: 'row', 
    justifyContent: 'space-between', 
    alignItems: 'center', 
    marginHorizontal: 15, 
    marginBottom: 10
  },
  sectionHeading: { color: '#FFF', fontSize: 16, fontWeight: 'bold' },
  createEventHeaderBtn: { 
    flexDirection: 'row', 
    alignItems: 'center', 
    backgroundColor: 'rgba(255, 153, 0, 0.1)', 
    paddingHorizontal: 10, 
    paddingVertical: 5, 
    borderRadius: 6,
    borderWidth: 1,
    borderColor: 'rgba(255, 153, 0, 0.2)'
  },
  createEventHeaderBtnText: { color: '#FF9900', fontSize: 11, fontWeight: 'bold', marginLeft: 2 },
  
  ticketCard: { 
    flexDirection: 'row', 
    backgroundColor: 'rgba(255,255,255,0.02)', 
    borderRadius: 14, 
    marginBottom: 14, 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.05)',
    minHeight: 110,
    overflow: 'hidden'
  },
  ticketLeft: { flex: 1, flexDirection: 'row', padding: 10 },
  ticketImage: { width: 65, height: 85, borderRadius: 8, backgroundColor: '#111', marginRight: 10 },
  ticketMeta: { flex: 1, justifyContent: 'space-between' },
  ticketDateText: { color: '#FF9900', fontSize: 10, fontWeight: 'bold' },
  ticketTitle: { color: '#FFF', fontSize: 14, fontWeight: 'bold' },
  ticketDesc: { color: '#666', fontSize: 11, marginVertical: 1 },
  ticketStockRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 2 },
  badgeLabelContainer: { flexDirection: 'row', alignItems: 'center' },
  ticketStockLabel: { color: '#555', fontSize: 10, marginRight: 2 },
  ticketStockValue: { color: '#FFF', fontSize: 10, fontWeight: 'bold' },
  outOfStockText: { color: '#FF6B6B' },
  ticketCardPrice: { color: '#00FFCC', fontSize: 13, fontWeight: 'bold' },
  
  ticketDivider: { 
    width: 20, 
    justifyContent: 'space-between', 
    alignItems: 'center', 
    backgroundColor: 'transparent',
    overflow: 'hidden'
  },
  ticketHoleTop: { 
    width: 20, 
    height: 10, 
    borderRadius: 10, 
    backgroundColor: '#090915', 
    marginTop: -5,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)'
  },
  ticketHoleBottom: { 
    width: 20, 
    height: 10, 
    borderRadius: 10, 
    backgroundColor: '#090915', 
    marginBottom: -5,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)'
  },
  
  ticketRight: { 
    width: 76, 
    backgroundColor: 'rgba(255,255,255,0.03)', 
    justifyContent: 'center', 
    alignItems: 'center',
    padding: 6
  },
  ticketActionBtn: { 
    backgroundColor: '#FF9900', 
    width: '100%', 
    paddingVertical: 7, 
    borderRadius: 8, 
    alignItems: 'center', 
    justifyContent: 'center',
    marginBottom: 6
  },
  ticketActionBtnTxt: { color: '#000', fontSize: 10, fontWeight: 'bold' },
  ticketCartAddBtn: {
    width: '100%',
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    borderRadius: 8,
    paddingVertical: 6,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 6
  },
  ticketEditBtn: { 
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 4,
    borderRadius: 4,
    backgroundColor: 'rgba(255,255,255,0.05)',
    width: '100%'
  },
  ticketEditBtnTxt: { color: '#FFF', fontSize: 9, fontWeight: 'bold', marginLeft: 2 },

  // Transit
  transitCard: {
    flexDirection: 'row',
    backgroundColor: 'rgba(255,255,255,0.02)',
    borderRadius: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)',
    padding: 12,
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  transitLeft: { flexDirection: 'row', alignItems: 'center', flex: 1 },
  transitIconContainer: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(255,153,0,0.1)',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
    borderWidth: 1,
    borderColor: 'rgba(255,153,0,0.15)'
  },
  transitMeta: { flex: 1 },
  transitTitle: { color: '#FFF', fontSize: 14, fontWeight: 'bold' },
  transitSub: { color: '#555', fontSize: 10, marginTop: 1 },
  transitPrice: { color: '#00FFCC', fontSize: 13, fontWeight: 'bold', marginTop: 2 },
  transitRight: { flexDirection: 'row', alignItems: 'center' },
  transitBuyNowBtn: {
    backgroundColor: '#FF9900',
    borderRadius: 8,
    paddingVertical: 7,
    paddingHorizontal: 10,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 6
  },
  transitBuyNowBtnText: { color: '#000', fontSize: 10, fontWeight: 'bold' },
  transitCartBtn: {
    width: 32,
    height: 32,
    borderRadius: 8,
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    justifyContent: 'center',
    alignItems: 'center'
  },

  // Purchased passes
  myPassCard: {
    flexDirection: 'row',
    backgroundColor: 'rgba(255,255,255,0.02)',
    borderRadius: 14,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)',
    padding: 12,
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  myPassLeft: { flexDirection: 'row', alignItems: 'center', flex: 1 },
  myPassIconBg: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)'
  },
  myPassDetails: { flex: 1 },
  myPassTitle: { color: '#FFF', fontSize: 14, fontWeight: 'bold' },
  myPassSubtitle: { color: '#555', fontSize: 10, marginTop: 1 },
  myPassPrice: { color: '#6C63FF', fontSize: 12, fontWeight: 'bold', marginTop: 2 },
  myPassRight: { marginLeft: 8 },
  tapToRideBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,153,0,0.1)',
    borderRadius: 15,
    paddingVertical: 5,
    paddingHorizontal: 8,
    borderWidth: 1,
    borderColor: 'rgba(255,153,0,0.15)'
  },
  tapToRideText: { color: '#FF9900', fontSize: 9, fontWeight: 'bold' },

  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', paddingVertical: 40 },
  loadingText: { color: '#888', marginTop: 10 },
  listPadding: { paddingHorizontal: 15, paddingBottom: 40 },
  emptyState: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingVertical: 50 },
  emptyStateTitle: { color: '#FFF', fontSize: 15, fontWeight: 'bold', marginTop: 10 },
  emptyStateSub: { color: '#555', fontSize: 11, marginTop: 2, textAlign: 'center' },

  // Bottom Sheet Modal
  expressModalBg: { flex: 1, backgroundColor: 'rgba(0,0,0,0.65)', justifyContent: 'flex-end' },
  expressModalDismissArea: { flex: 1 },
  expressSheetContent: { 
    backgroundColor: '#0F0F1E', 
    borderTopLeftRadius: 20, 
    borderTopRightRadius: 20, 
    paddingHorizontal: 20, 
    paddingTop: 10,
    maxHeight: '80%', 
    borderTopWidth: 1, 
    borderColor: 'rgba(255,255,255,0.08)' 
  },
  sheetGrabber: { width: 36, height: 4, backgroundColor: 'rgba(255,255,255,0.2)', borderRadius: 2, alignSelf: 'center', marginBottom: 12 },
  expressHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 15 },
  expressTitle: { color: '#FFF', fontSize: 16, fontWeight: 'bold' },
  expressCloseBtn: { width: 32, height: 32, borderRadius: 16, backgroundColor: 'rgba(255,255,255,0.05)', justifyContent: 'center', alignItems: 'center' },
  expressItemScroll: { flexGrow: 0 },
  expressItemRow: { 
    flexDirection: 'row', 
    backgroundColor: 'rgba(255,255,255,0.03)', 
    borderRadius: 10, 
    padding: 10, 
    marginBottom: 12, 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.05)',
    alignItems: 'center'
  },
  expressItemImage: { width: 60, height: 60, borderRadius: 6, backgroundColor: '#111', marginRight: 12 },
  expressItemMeta: { flex: 1, justifyContent: 'center' },
  expressItemName: { color: '#FFF', fontSize: 13, fontWeight: 'bold' },
  expressItemMerchant: { color: '#666', fontSize: 10, marginTop: 1 },
  expressItemPrice: { color: '#FF9900', fontSize: 14, fontWeight: 'bold', marginTop: 3 },
  expressSection: { borderBottomWidth: 1, borderBottomColor: 'rgba(255,255,255,0.05)', paddingVertical: 12 },
  expressSectionTitle: { color: '#FFF', fontSize: 13, fontWeight: 'bold', marginBottom: 6 },
  expressAddressInput: { 
    backgroundColor: 'rgba(255,255,255,0.04)', 
    borderRadius: 8, 
    padding: 10, 
    color: '#FFF', 
    borderColor: 'rgba(255,255,255,0.08)', 
    borderWidth: 1, 
    minHeight: 44, 
    fontSize: 13 
  },
  balanceRow: { flexDirection: 'row', justifyContent: 'space-between', marginVertical: 3 },
  balanceLabel: { color: '#888', fontSize: 12 },
  balanceValue: { color: '#FFF', fontSize: 12, fontWeight: 'bold' },
  expressSecurityFooter: { color: '#444', fontSize: 10, textAlign: 'center', marginTop: 12, marginBottom: 5 },

  // Swipe to Pay Slider Styles
  swipeTrack: {
    height: 54,
    width: '100%',
    borderRadius: 27,
    backgroundColor: '#1C1C3A',
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    overflow: 'hidden',
    marginTop: 20,
    marginBottom: 5
  },
  swipeText: { color: '#FF9900', fontSize: 13, fontWeight: 'bold', letterSpacing: 0.5 },
  swipeHandle: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#FF9900',
    justifyContent: 'center',
    alignItems: 'center',
    position: 'absolute',
    left: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 3,
    elevation: 4
  },

  // Modals (Pass, Edit, Create)
  modalBg: { flex: 1, backgroundColor: 'rgba(0,0,0,0.8)', justifyContent: 'center', alignItems: 'center', padding: 20 },
  modalContent: { 
    backgroundColor: '#131326', 
    width: '100%', 
    borderRadius: 20, 
    padding: 20, 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.08)' 
  },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 15 },
  modalTitle: { color: '#FFF', fontSize: 18, fontWeight: 'bold' },
  inputLabel: { color: '#888', fontSize: 11, fontWeight: 'bold', marginBottom: 4, marginTop: 10 },
  modalInput: { 
    backgroundColor: 'rgba(255,255,255,0.05)', 
    borderRadius: 10, 
    color: '#FFF', 
    fontSize: 13, 
    padding: 10, 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.05)' 
  },
  inputRow: { flexDirection: 'row', justifyContent: 'space-between' },
  modalSubmitBtn: { 
    backgroundColor: '#FF9900', 
    borderRadius: 10, 
    paddingVertical: 12, 
    alignItems: 'center', 
    justifyContent: 'center', 
    marginTop: 20 
  },
  modalSubmitBtnText: { color: '#000', fontSize: 14, fontWeight: 'bold' },
  disabledBtn: { backgroundColor: '#444' },

  passModalContent: {
    backgroundColor: '#0F0F1E',
    width: '90%',
    borderRadius: 20,
    padding: 20,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    alignItems: 'center'
  },
  passModalHeader: { flexDirection: 'row', alignItems: 'center', width: '100%', marginBottom: 15 },
  passHeaderIconBg: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(255,255,255,0.05)',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 10
  },
  passModalTitle: { color: '#888', fontSize: 10, fontWeight: 'bold', letterSpacing: 2, flex: 1 },
  passCloseBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(255,255,255,0.05)',
    alignItems: 'center',
    justifyContent: 'center'
  },
  passNameText: { color: '#FFF', fontSize: 18, fontWeight: 'bold', textAlign: 'center' },
  passExtraText: { color: '#555', fontSize: 11, marginTop: 2, textAlign: 'center', marginBottom: 20 },
  qrPulseOuter: { width: 210, height: 210, alignItems: 'center', justifyContent: 'center', marginBottom: 20 },
  qrPulseContainer: {
    width: 200,
    height: 200,
    borderRadius: 15,
    backgroundColor: 'rgba(255,255,255,0.02)',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: '#FF9900',
    padding: 10
  },
  qrPassWrapper: { width: 170, height: 170, position: 'relative', backgroundColor: '#FFF', borderRadius: 8, overflow: 'hidden' },
  scannerLine: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: 3,
    backgroundColor: '#FF9900',
    opacity: 0.8,
    shadowColor: '#FF9900',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.8,
    shadowRadius: 4,
    elevation: 5
  },
  tapPromptContainer: { flexDirection: 'row', alignItems: 'center', marginBottom: 20 },
  wifiIcon: { marginRight: 6 },
  tapPromptText: { color: '#FF9900', fontSize: 11, fontWeight: 'bold' },
  passSubmitBtn: {
    backgroundColor: '#6C63FF',
    borderRadius: 10,
    paddingVertical: 12,
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center'
  },
  passSubmitBtnText: { color: '#FFF', fontSize: 14, fontWeight: 'bold' },

  // Sub Tab Styles
  subTabContainer: {
    flexDirection: 'row',
    backgroundColor: 'rgba(255,255,255,0.02)',
    borderRadius: 10,
    marginHorizontal: 15,
    padding: 3,
    marginBottom: 15,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.04)'
  },
  subTabButton: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 8,
    borderRadius: 8
  },
  activeSubTabButton: {
    backgroundColor: 'rgba(255,255,255,0.05)'
  },
  subTabText: {
    color: '#666',
    fontSize: 12,
    fontWeight: 'bold'
  },
  activeSubTabText: {
    color: '#FFF'
  },
  // StubHub Styles
  stubHubGenreContainer: {
    marginHorizontal: 15,
    marginBottom: 10
  },
  genrePills: {
    paddingVertical: 5
  },
  stubHubGenrePill: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: 'rgba(255,255,255,0.04)',
    marginRight: 8,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.06)'
  },
  activeStubHubGenrePill: {
    backgroundColor: '#6C63FF',
    borderColor: '#8A84FF'
  },
  stubHubGenrePillText: {
    color: '#888',
    fontSize: 12,
    fontWeight: 'bold'
  },
  activeStubHubGenrePillText: {
    color: '#FFF'
  },

  stubHubEventCard: {
    flexDirection: 'row',
    backgroundColor: 'rgba(255, 255, 255, 0.03)',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.07)',
    marginBottom: 12,
    padding: 12,
    alignItems: 'center'
  },
  stubHubDateBadge: {
    width: 60,
    borderRadius: 10,
    overflow: 'hidden',
    backgroundColor: '#1E1E38',
    alignItems: 'center',
    marginRight: 12,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)'
  },
  stubHubMonthBg: {
    backgroundColor: '#6C63FF',
    width: '100%',
    paddingVertical: 4,
    alignItems: 'center'
  },
  stubHubMonthText: {
    color: '#FFF',
    fontSize: 10,
    fontWeight: 'bold'
  },
  stubHubDayBg: {
    paddingVertical: 6,
    alignItems: 'center',
    width: '100%'
  },
  stubHubDayText: {
    color: '#FFF',
    fontSize: 18,
    fontWeight: 'bold'
  },
  stubHubWeekdayText: {
    color: '#888',
    fontSize: 9,
    marginTop: 1
  },
  stubHubDetailsCol: {
    flex: 1,
    justifyContent: 'center',
    paddingRight: 8
  },
  stubHubEventTitle: {
    color: '#FFF',
    fontSize: 14,
    fontWeight: 'bold',
    marginBottom: 3
  },
  stubHubEventVenue: {
    color: '#AAA',
    fontSize: 11,
    marginBottom: 6,
    flexDirection: 'row',
    alignItems: 'center'
  },
  stubHubUrgencyBadge: {
    alignSelf: 'flex-start',
    borderRadius: 4,
    borderWidth: 1,
    paddingHorizontal: 6,
    paddingVertical: 2
  },
  stubHubUrgencyText: {
    fontSize: 9,
    fontWeight: 'bold'
  },
  urgencySoldOut: {
    backgroundColor: 'rgba(100, 100, 100, 0.15)',
    borderColor: '#555',
    color: '#888'
  },
  urgencyCritical: {
    backgroundColor: 'rgba(239, 68, 68, 0.15)',
    borderColor: '#EF4444',
    color: '#EF4444'
  },
  urgencyHigh: {
    backgroundColor: 'rgba(245, 158, 11, 0.15)',
    borderColor: '#F59E0B',
    color: '#F59E0B'
  },
  urgencyNormal: {
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
    borderColor: '#10B981',
    color: '#10B981'
  },

  stubHubActionCol: {
    alignItems: 'flex-end',
    width: 90
  },
  stubHubPriceLabel: {
    color: '#888',
    fontSize: 9
  },
  stubHubPriceText: {
    color: '#00FFCC',
    fontSize: 15,
    fontWeight: 'bold'
  },
  stubHubJmdText: {
    color: '#888',
    fontSize: 8,
    fontWeight: 'bold',
    marginTop: -2
  },
  stubHubSeeTicketsBtn: {
    backgroundColor: '#6C63FF',
    borderRadius: 8,
    paddingVertical: 6,
    paddingHorizontal: 10,
    marginTop: 6,
    width: '100%',
    alignItems: 'center'
  },
  disabledSeeBtn: {
    backgroundColor: '#444'
  },
  stubHubSeeTicketsText: {
    color: '#FFF',
    fontSize: 11,
    fontWeight: 'bold'
  },
  stubHubEditEventBtn: {
    paddingVertical: 4,
    paddingHorizontal: 10,
    marginTop: 4
  },
  stubHubEditEventText: {
    color: 'rgba(255,255,255,0.4)',
    fontSize: 10,
    textDecorationLine: 'underline'
  },

  // Bottom Sheet Custom Styles
  stubHubZoneSheet: {
    backgroundColor: '#0F0F1E',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    paddingHorizontal: 20,
    paddingTop: 10,
    height: '85%',
    borderTopWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)'
  },
  stubHubZoneHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12
  },
  stubHubZoneSheetTitle: {
    color: '#FFF',
    fontSize: 16,
    fontWeight: 'bold'
  },
  stubHubZoneSheetVenue: {
    color: '#888',
    fontSize: 11,
    marginTop: 1
  },
  stubHubMapContainer: {
    backgroundColor: '#16162A',
    borderRadius: 14,
    padding: 12,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)',
    marginBottom: 15
  },
  stubHubStage: {
    width: '80%',
    height: 36,
    backgroundColor: '#2E2E4A',
    borderRadius: 6,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#6C63FF',
    marginBottom: 15,
    shadowColor: '#6C63FF',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.5,
    shadowRadius: 5
  },
  stubHubStageText: {
    color: '#FFF',
    fontSize: 11,
    fontWeight: 'bold',
    letterSpacing: 2
  },
  stubHubSectionsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    width: '100%',
    marginBottom: 8
  },
  stubHubSectionBox: {
    width: '28%',
    height: 50,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: 'transparent'
  },
  sectionBoxVvip: {
    backgroundColor: 'rgba(245, 158, 11, 0.25)',
    borderColor: 'rgba(245, 158, 11, 0.4)'
  },
  sectionBoxVip: {
    backgroundColor: 'rgba(59, 130, 246, 0.25)',
    borderColor: 'rgba(59, 130, 246, 0.4)'
  },
  sectionBoxGa: {
    backgroundColor: 'rgba(16, 185, 129, 0.25)',
    borderColor: 'rgba(16, 185, 129, 0.4)'
  },
  sectionBoxSelected: {
    borderColor: '#FFF',
    borderWidth: 2,
    shadowColor: '#FFF',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.6,
    shadowRadius: 4
  },
  sectionBoxLabel: {
    color: '#FFF',
    fontSize: 11,
    fontWeight: 'bold'
  },
  sectionBoxPrice: {
    color: '#AAA',
    fontSize: 9,
    marginTop: 2
  },
  mapHintText: {
    color: '#555',
    fontSize: 9,
    textAlign: 'center',
    marginTop: 4
  },

  selectTierHeading: {
    color: '#FFF',
    fontSize: 13,
    fontWeight: 'bold',
    marginBottom: 8
  },
  tierSelectorContainer: {
    marginBottom: 15
  },
  tierRowOption: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.02)',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)',
    padding: 10,
    marginBottom: 8
  },
  tierRowOptionActive: {
    backgroundColor: 'rgba(108, 99, 255, 0.1)',
    borderColor: '#6C63FF'
  },
  tierColorIndicator: {
    width: 10,
    height: 10,
    borderRadius: 5,
    marginRight: 10
  },
  tierRowTitle: {
    color: '#FFF',
    fontSize: 13,
    fontWeight: 'bold'
  },
  tierRowRowInfo: {
    color: '#555',
    fontSize: 10,
    marginTop: 1
  },
  tierRowPrice: {
    color: '#00FFCC',
    fontSize: 14,
    fontWeight: 'bold',
    marginLeft: 10
  },

  pricingSummarySection: {
    backgroundColor: 'rgba(255,255,255,0.02)',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)',
    padding: 12,
    marginBottom: 15
  },
  qtyContainerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.05)',
    paddingBottom: 10
  },
  qtyLabel: {
    color: '#FFF',
    fontSize: 13,
    fontWeight: 'bold'
  },
  qtyControlBlock: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.06)',
    borderRadius: 20,
    padding: 3
  },
  qtyButton: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(255,255,255,0.1)',
    alignItems: 'center',
    justifyContent: 'center'
  },
  qtyValue: {
    color: '#FFF',
    fontSize: 14,
    fontWeight: 'bold',
    paddingHorizontal: 15
  },

  breakoutBlock: {},
  breakoutRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginVertical: 3
  },
  breakoutLabel: {
    color: '#666',
    fontSize: 11
  },
  breakoutValue: {
    color: '#FFF',
    fontSize: 11,
    fontWeight: '500'
  },
  breakoutTotalRow: {
    borderTopWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.05)',
    paddingTop: 8,
    marginTop: 6
  },
  totalPriceLabel: {
    color: '#FFF',
    fontSize: 13,
    fontWeight: 'bold'
  },
  totalPriceValue: {
    color: '#FF9900',
    fontSize: 15,
    fontWeight: 'bold'
  },
  stubHubAddCartFallback: {
    backgroundColor: 'rgba(255,255,255,0.03)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    borderRadius: 20,
    paddingVertical: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 10
  },
  stubHubAddCartFallbackText: {
    color: '#FFF',
    fontSize: 11,
    fontWeight: 'bold'
  }
});


