import { RealtimeIndicator } from './realtime-indicator';

export function Header() {
  return (
    <header
      className="sticky top-0 z-20 h-14 flex items-center justify-end px-6 shadow-sm"
      style={{ backgroundColor: '#FAF7F2', borderBottom: '1px solid #EBE4D9' }}
    >
      <RealtimeIndicator />
    </header>
  );
}
