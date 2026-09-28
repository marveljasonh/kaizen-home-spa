'use client';

import { useEffect, useRef } from 'react';
import { createClient } from '@/lib/supabase/client';
import type { RealtimePostgresChangesPayload } from '@supabase/supabase-js';

type ChangePayload = RealtimePostgresChangesPayload<Record<string, unknown>>;

// Subscribes to postgres_changes for a table and invokes onChange on every event.
// onChange is always read from a ref, so callers don't need to memoize it.
export function useRealtimeTable(channelName: string, table: string, onChange: (payload: ChangePayload) => void) {
  const onChangeRef = useRef(onChange);

  useEffect(() => {
    onChangeRef.current = onChange;
  });

  useEffect(() => {
    const supabase = createClient();
    const channel = supabase
      .channel(channelName)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table },
        (payload: ChangePayload) => onChangeRef.current(payload)
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [channelName, table]);
}
