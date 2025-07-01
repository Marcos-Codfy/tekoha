'use client';

import { Button } from '@/components/ui/button';
import { Home, LayoutGrid, User, Settings } from 'lucide-react';
import Link from 'next/link';
import Image from 'next/image';

export default function DashboardPage() {
  return (
    <div className="flex flex-col min-h-screen bg-background">
      <main className="flex-1 p-6 pb-24">
        <h1 className="text-4xl font-bold text-foreground">Bem-vindo ao Tekohá</h1>
        <p className="text-lg text-muted-foreground mt-2">Navegue pelo menu abaixo para começar.</p>
      </main>

      <footer className="fixed bottom-0 left-0 right-0 bg-card border-t border-border">
        <nav className="container mx-auto h-20 flex justify-between items-center">
          <div className="flex justify-around items-center flex-1">
            <Link href="/dashboard" passHref>
              <Button className="flex flex-col h-auto p-3 space-y-1 rounded-xl">
                <Home className="h-6 w-6" />
                <span className="text-xs font-medium">Início</span>
              </Button>
            </Link>
            <Link href="#" passHref>
              <Button variant="ghost" className="flex flex-col h-auto p-3 space-y-1 rounded-xl text-muted-foreground">
                <LayoutGrid className="h-6 w-6" />
                <span className="text-xs font-medium">Projetos</span>
              </Button>
            </Link>
          </div>

          <div className="relative -top-6">
            <Link href="/dashboard">
              <div className="bg-background rounded-full p-1 shadow-lg">
                <Image
                  src="https://placehold.co/64x64.png"
                  alt="Tekohá Logo"
                  width={64}
                  height={64}
                  data-ai-hint="bird mascot"
                  className="rounded-full"
                />
              </div>
            </Link>
          </div>
          
          <div className="flex justify-around items-center flex-1">
            <Link href="#" passHref>
              <Button variant="ghost" className="flex flex-col h-auto p-3 space-y-1 rounded-xl text-muted-foreground">
                <User className="h-6 w-6" />
                <span className="text-xs font-medium">Perfil</span>
              </Button>
            </Link>
            <Link href="#" passHref>
              <Button variant="ghost" className="flex flex-col h-auto p-3 space-y-1 rounded-xl text-muted-foreground">
                <Settings className="h-6 w-6" />
                <span className="text-xs font-medium">Ajustes</span>
              </Button>
            </Link>
          </div>
        </nav>
      </footer>
    </div>
  );
}
