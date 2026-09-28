'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  Leaf,
  LayoutDashboard,
  CalendarCheck,
  Sparkles,
  UserCheck,
  Truck,
  Building2,
  Tag,
  Users,
  LogOut,
  Briefcase,
  ChevronDown,
  Gift,
  Star,
  Trophy,
  Globe,
} from 'lucide-react';
import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { cn } from '@/lib/utils';

const NAV_TOP = [
  { href: '/dashboard',  label: 'Dashboard',  icon: LayoutDashboard },
  { href: '/bookings',   label: 'Bookings',   icon: CalendarCheck },
  { href: '/treatments', label: 'Treatments', icon: Sparkles },
];

const EMPLOYEE_ITEMS = [
  { href: '/therapists', label: 'Therapists', icon: UserCheck },
  { href: '/riders',     label: 'Riders',     icon: Truck },
];

const POINTS_REWARDS_ITEMS = [
  { href: '/points',  label: 'Point Settings', icon: Star },
  { href: '/rewards', label: 'Rewards',         icon: Trophy },
];

const NAV_BOTTOM = [
  { href: '/branches',  label: 'Branches',  icon: Building2 },
  { href: '/customers', label: 'Customers', icon: Users },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  const isEmployeePath      = pathname.startsWith('/therapists') || pathname.startsWith('/riders');
  const isPointsRewardsPath = pathname.startsWith('/points')     || pathname.startsWith('/rewards');

  const [openMenu, setOpenMenu] = useState<string | null>(
    isEmployeePath      ? 'employee'       :
    isPointsRewardsPath ? 'points-rewards' : null
  );

  async function handleSignOut() {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push('/login');
  }

  const navLink = (href: string, label: string, Icon: React.ElementType) => {
    const active = pathname === href || pathname.startsWith(href + '/');
    return (
      <Link
        key={href}
        href={href}
        onClick={() => setOpenMenu(null)}
        className={cn(
          'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
          active ? 'text-white' : 'hover:bg-white/10 hover:text-white'
        )}
        style={active ? { backgroundColor: '#6B7057', color: 'white' } : { color: '#C5CAB0' }}
      >
        <Icon className="w-4 h-4 flex-shrink-0" />
        {label}
      </Link>
    );
  };

  const subItems = (
    items: { href: string; label: string; icon: React.ElementType }[]
  ) => (
    <div className="mt-1 mx-2 py-1 rounded-lg space-y-0.5" style={{ backgroundColor: 'rgba(0,0,0,0.15)' }}>
      {items.map(({ href, label, icon: Icon }) => {
        const active = pathname === href || pathname.startsWith(href + '/');
        return (
          <Link
            key={href}
            href={href}
            className={cn(
              'flex items-center gap-3 px-3 py-2 mx-1 rounded-lg text-sm font-medium transition-colors border-l-2',
              active ? 'text-white' : 'hover:bg-white/10 hover:text-white'
            )}
            style={
              active
                ? { backgroundColor: '#6B7057', color: 'white', borderColor: 'rgba(255,255,255,0.5)' }
                : { color: '#C5CAB0', borderColor: 'rgba(255,255,255,0.2)' }
            }
          >
            <Icon className="w-4 h-4 flex-shrink-0" />
            {label}
          </Link>
        );
      })}
    </div>
  );

  const accordion = (
    key: string,
    label: string,
    Icon: React.ElementType,
    items: { href: string; label: string; icon: React.ElementType }[],
    isActivePath: boolean
  ) => {
    const isOpen = openMenu === key;
    return (
      <div>
        <button
          onClick={() => setOpenMenu(isOpen ? null : key)}
          className={cn(
            'flex items-center gap-3 w-full px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
            isActivePath ? 'text-white' : 'hover:bg-white/10 hover:text-white'
          )}
          style={
            isActivePath
              ? { backgroundColor: '#6B7057', color: 'white' }
              : { color: '#C5CAB0' }
          }
        >
          <Icon className="w-4 h-4 flex-shrink-0" />
          <span className="flex-1 text-left">{label}</span>
          <ChevronDown
            className="w-3.5 h-3.5 flex-shrink-0 transition-transform duration-200"
            style={{ transform: isOpen ? 'rotate(0deg)' : 'rotate(-90deg)' }}
          />
        </button>
        {isOpen && subItems(items)}
      </div>
    );
  };

  return (
    <aside
      className="fixed inset-y-0 left-0 w-64 flex flex-col z-30"
      style={{ backgroundColor: '#4E523B' }}
    >
      {/* Logo */}
      <div className="flex items-center gap-3 px-5 py-5 border-b border-white/10">
        <div className="w-9 h-9 rounded-lg bg-white/15 flex items-center justify-center flex-shrink-0">
          <Leaf className="w-5 h-5 text-white" />
        </div>
        <div>
          <p className="font-bold text-white text-base leading-tight">Kaizen</p>
          <p className="text-xs leading-tight" style={{ color: '#C5CAB0' }}>Home Spa Admin</p>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        {NAV_TOP.map(({ href, label, icon: Icon }) => navLink(href, label, Icon))}

        {/* Employee accordion */}
        <div className="pt-1 border-t border-white/10">
          {accordion('employee', 'Employee', Briefcase, EMPLOYEE_ITEMS, isEmployeePath)}
        </div>

        <div className="pb-1 border-b border-white/10" />

        {navLink('/branches', 'Branches', Building2)}
        {navLink('/promos', 'Promos', Tag)}

        {/* Points & Rewards accordion */}
        {accordion('points-rewards', 'Points & Rewards', Gift, POINTS_REWARDS_ITEMS, isPointsRewardsPath)}

        {navLink('/customers', 'Customers', Users)}
        {navLink('/website', 'Website', Globe)}
      </nav>

      {/* Sign out */}
      <div className="px-3 py-4 border-t border-white/10">
        <button
          onClick={handleSignOut}
          className="flex items-center gap-3 w-full px-3 py-2.5 rounded-lg text-sm font-medium hover:bg-white/10 hover:text-white transition-colors"
          style={{ color: '#C5CAB0' }}
        >
          <LogOut className="w-4 h-4 flex-shrink-0" />
          Sign Out
        </button>
      </div>
    </aside>
  );
}
