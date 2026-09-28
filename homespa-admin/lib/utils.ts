import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatRupiah(amount: number): string {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0,
  }).format(amount);
}

export function formatDate(date: string | Date, withTime = false): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  if (withTime) {
    return (
      new Intl.DateTimeFormat('id-ID', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        timeZone: 'Asia/Jakarta',
      }).format(d) + ' WIB'
    );
  }
  return new Intl.DateTimeFormat('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    timeZone: 'Asia/Jakarta',
  }).format(d);
}

export const STATUS_LABELS: Record<string, string> = {
  pending: 'Pending',
  accepted: 'Accepted',
  therapist_assigned: 'Therapist Assigned',
  rider_assigned: 'Rider Assigned',
  on_the_way: 'On the Way',
  arrived: 'Arrived',
  in_progress: 'In Progress',
  completed: 'Completed',
  cancelled: 'Cancelled',
};

export const STATUS_COLORS: Record<string, string> = {
  pending: 'bg-amber-100 text-amber-800',
  accepted: 'bg-sky-100 text-sky-800',
  therapist_assigned: 'bg-teal-100 text-teal-800',
  rider_assigned: 'bg-cyan-100 text-cyan-800',
  on_the_way: 'bg-indigo-100 text-indigo-800',
  arrived: 'bg-violet-100 text-violet-800',
  in_progress: 'bg-purple-100 text-purple-800',
  completed: 'bg-emerald-100 text-emerald-800',
  cancelled: 'bg-rose-100 text-rose-800',
};
