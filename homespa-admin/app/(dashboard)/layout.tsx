import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { Sidebar } from '@/components/layout/sidebar';
import { Header } from '@/components/layout/header';

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login');
  }

  return (
    <div className="flex h-full">
      <Sidebar />
      <div className="ml-64 flex-1 flex flex-col min-h-screen">
        <Header />
        <main className="flex-1 p-6" style={{ backgroundColor: '#FAF7F2' }}>
          {children}
        </main>
      </div>
    </div>
  );
}
