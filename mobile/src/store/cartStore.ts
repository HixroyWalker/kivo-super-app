import { create } from 'zustand';

interface CartItem {
  product_id: string;
  name: string;
  price: number;
  quantity: number;
  merchant_id: string;
}

interface CartState {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  removeItem: (product_id: string) => void;
  clearCart: () => void;
  total: () => number;
}

export const useCartStore = create<CartState>((set, get) => ({
  items: [],
  addItem: (item) => set((state) => {
    const existing = state.items.find(i => i.product_id === item.product_id);
    if (existing) {
      return { items: state.items.map(i => i.product_id === item.product_id ? { ...i, quantity: i.quantity + item.quantity } : i) };
    }
    return { items: [...state.items, item] };
  }),
  removeItem: (product_id) => set((state) => ({ items: state.items.filter(i => i.product_id !== product_id) })),
  clearCart: () => set({ items: [] }),
  total: () => get().items.reduce((acc, item) => acc + (item.price * item.quantity), 0),
}));
