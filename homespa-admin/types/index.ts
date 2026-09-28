export type BookingStatus =
  | 'pending'
  | 'accepted'
  | 'therapist_assigned'
  | 'rider_assigned'
  | 'on_the_way'
  | 'arrived'
  | 'in_progress'
  | 'completed'
  | 'cancelled';

export interface BookingItem {
  id: string;
  booking_id: string;
  treatment_id: string;
  duration_minutes: number;
  price: number;
}

export interface BookingAddon {
  id: string;
  booking_id: string;
  addon_id: string;
  price: number;
}

export interface RiderAssignment {
  id: string;
  rider_id: string;
  booking_id: string;
  status: string;
  assigned_at: string;
}

export interface Booking {
  id: string;
  client_id: string;
  branch_id: string;
  therapist_id: string | null;
  rider_id: string | null;
  scheduled_at: string;
  address_snapshot: string;
  payment_method: string;
  status: BookingStatus;
  subtotal: number;
  discount_amount: number;
  tax_amount: number;
  total_amount: number;
  notes: string | null;
  voucher_id: string | null;
  created_at: string;
}

export interface TherapistProfile {
  id: string;
  profile_id: string;
  branch_id: string | null;
  bio: string | null;
  specialties: string[];
  rating_avg: number;
  total_reviews: number;
  is_available: boolean;
  profile: { full_name: string | null; avatar_url: string | null } | null;
}

export interface Category {
  id: string;
  name: string;
  icon_url: string | null;
  sort_order?: number;
}

export interface Treatment {
  id: string;
  name: string;
  description: string;
  category_id: string;
  base_price?: number;
  is_active: boolean;
  sort_order: number;
  image_url: string | null;
  created_at: string;
}

export interface TreatmentDuration {
  id: string;
  treatment_id: string;
  duration_minutes: number;
  price: number;
  is_active: boolean;
}

export interface Addon {
  id: string;
  name: string;
  description: string | null;
  price: number;
  is_active: boolean;
}

export interface Voucher {
  id: string;
  code: string;
  description: string | null;
  discount_type: 'percentage' | 'fixed';
  discount_value: number;
  min_purchase: number;
  valid_until: string;
  is_active: boolean;
  created_at: string;
}

export interface Banner {
  id: string;
  title: string;
  subtitle: string | null;
  image_url: string | null;
  is_active: boolean;
  sort_order?: number;
  valid_from: string | null;
  valid_until: string | null;
  action_type?: string | null;
  action_value?: string | null;
}

export interface Branch {
  id: string;
  name: string;
  address: string | null;
  lat: number | null;
  lng: number | null;
  radius_km: number | null;
  capacity: number | null;
  is_active: boolean;
}

export interface Profile {
  id: string;
  full_name: string | null;
  avatar_url: string | null;
  phone: string | null;
  role: string;
}

export interface ClientProfile {
  user_id: string;
  completed_orders_count: number;
  loyalty_progress: number;
}

export interface RiderProfile {
  id: string;
  profile_id: string;
  branch_id: string | null;
  vehicle_type: string | null;
  plate_number: string | null;
  is_available: boolean;
  profile: { full_name: string | null; avatar_url: string | null } | null;
}

export interface PreferredTherapist {
  client_id: string;
  therapist_id: string;
}
