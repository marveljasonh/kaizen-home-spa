'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Leaf } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);

    const supabase = createClient();
    const { error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (authError) {
      setError(authError.message);
      setLoading(false);
      return;
    }

    router.push('/dashboard');
    router.refresh();
  }

  const inputCls = 'w-full px-3 py-2.5 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B] transition';
  const inputStyle = { borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' };

  return (
    <div className="min-h-screen flex items-center justify-center px-4" style={{ backgroundColor: '#FAF7F2' }}>
      <div className="w-full max-w-md">
        <div className="bg-white rounded-2xl shadow-lg p-8" style={{ border: '1px solid #EBE4D9' }}>
          <div className="flex flex-col items-center mb-8">
            <div className="w-16 h-16 rounded-full flex items-center justify-center mb-4 shadow-md" style={{ backgroundColor: '#4E523B' }}>
              <Leaf className="w-8 h-8 text-white" />
            </div>
            <h1 className="text-2xl font-bold tracking-tight" style={{ color: '#2C2C2A' }}>
              Kaizen Home Spa
            </h1>
            <p className="text-sm mt-1" style={{ color: '#7A7A72' }}>
              Admin Dashboard
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1.5" style={{ color: '#3D3D38' }}>
                Email address
              </label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@example.com"
                className={inputCls}
                style={inputStyle}
              />
            </div>

            <div>
              <label className="block text-sm font-medium mb-1.5" style={{ color: '#3D3D38' }}>
                Password
              </label>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className={inputCls}
                style={inputStyle}
              />
            </div>

            {error && (
              <div className="p-3 rounded-lg border" style={{ backgroundColor: '#FEF2F2', borderColor: '#FECACA' }}>
                <p className="text-sm text-red-700">{error}</p>
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full py-2.5 px-4 rounded-lg text-white font-medium text-sm transition disabled:opacity-60 disabled:cursor-not-allowed mt-2"
              style={{ backgroundColor: '#4E523B' }}
              onMouseEnter={(e) => { if (!loading) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
            >
              {loading ? 'Signing in...' : 'Sign in'}
            </button>
          </form>
        </div>

        <p className="text-center text-xs mt-6" style={{ color: '#9A9A90' }}>
          Kaizen Home Spa &copy; {new Date().getFullYear()}
        </p>
      </div>
    </div>
  );
}
