'use client';

import { useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { cn } from '@/lib/utils';

export function RealtimeIndicator() {
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    const supabase = createClient();
    const channel = supabase
      .channel('admin-realtime-status')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bookings' }, () => {})
      .subscribe((status) => {
        setIsConnected(status === 'SUBSCRIBED');
      });

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  return (
    <span
      className="flex items-center gap-1.5 text-xs font-medium"
      style={{ color: isConnected ? '#16A34A' : '#9A9A90' }}
    >
      <span
        className={cn('w-2 h-2 rounded-full flex-shrink-0', isConnected && 'animate-pulse')}
        style={{ backgroundColor: isConnected ? '#22C55E' : '#C5CAB0' }}
      />
      {isConnected ? 'Live' : 'Connecting…'}
    </span>
  );
}
