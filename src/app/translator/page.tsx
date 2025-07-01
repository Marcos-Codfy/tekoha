'use client';

import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle } from '@/components/ui/card';
import { Home, Trophy, Languages, Settings } from 'lucide-react';
import Link from 'next/link';
import Image from 'next/image';

export default function TranslatorPage() {
  return (
    <div className="flex flex-col min-h-screen bg-background">
      <svg width="0" height="0" className="absolute">
        <defs>
          <linearGradient id="icon-gradient" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="hsl(var(--primary))" />
            <stop offset="100%" stopColor="hsl(var(--accent))" />
          </linearGradient>
        </defs>
      </svg>
      <main className="flex-1 p-6 flex items-center justify-center">
        <Card className="w-full max-w-md">
            <CardHeader>
                <CardTitle className="text-center">Tradutor</CardTitle>
            </CardHeader>
        </Card>
      </main>

      <footer className="fixed bottom-0 left-0 right-0 bg-card border-t border-border">
        <nav className="container mx-auto h-20 flex justify-between items-center">
          <div className="flex justify-around items-center flex-1">
            <Link href="/dashboard" passHref>
              <Button variant="ghost" className="flex flex-col h-auto p-3 space-y-1 rounded-xl">
                <Home className="h-6 w-6" stroke="url(#icon-gradient)" />
                <span className="text-xs font-medium text-muted-foreground">Início</span>
              </Button>
            </Link>
            <Link href="/achievements" passHref>
              <Button variant="ghost" className="flex flex-col h-auto p-3 space-y-1 rounded-xl">
                <Trophy className="h-6 w-6" stroke="url(#icon-gradient)" />
                <span className="text-xs font-medium text-muted-foreground">Conquistas</span>
              </Button>
            </Link>
          </div>

          <div className="relative -top-6">
            <Link href="/dashboard">
              <div className="bg-background rounded-full p-1 shadow-lg">
                <Image
                  src="https://images.unsplash.com/photo-1543479201-17bcda84d43a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3NDE5ODJ8MHwxfHNlYXJjaHwxMnx8YXJhcmF8ZW58MHx8fHwxNzUxMzkxOTc2fDA&ixlib=rb-4.1.0&q=80&w=1080"
                  alt="Tekohá Logo"
                  width={64}
                  height={64}
                  data-ai-hint="bird mascot"
                  className="rounded-full object-cover"
                />
              </div>
            </Link>
          </div>
          
          <div className="flex justify-around items-center flex-1">
            <Link href="/settings" passHref>
              <Button variant="ghost" className="flex flex-col h-auto p-3 space-y-1 rounded-xl">
                <Settings className="h-6 w-6" stroke="url(#icon-gradient)" />
                <span className="text-xs font-medium text-muted-foreground">Config</span>
              </Button>
            </Link>
            <Link href="/translator" passHref>
              <Button className="flex flex-col h-auto p-3 space-y-1 rounded-xl">
                <Languages className="h-6 w-6" stroke="url(#icon-gradient)" />
                <span className="text-xs font-medium">Tradutor</span>
              </Button>
            </Link>
          </div>
        </nav>
      </footer>
    </div>
  );
}
