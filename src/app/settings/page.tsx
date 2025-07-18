'use client';

import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle } from '@/components/ui/card';
import { Home, Trophy, Languages, Settings } from 'lucide-react';
import Link from 'next/link';
import Image from 'next/image';

export default function SettingsPage() {
  return (
    <div className="flex flex-col min-h-screen bg-background">
      <main className="flex-1 p-6 pb-24 flex items-center justify-center">
        <Card className="w-full max-w-md">
            <CardHeader>
                <CardTitle className="text-center">Configurações</CardTitle>
            </CardHeader>
        </Card>
      </main>

      <footer className="fixed bottom-0 left-0 right-0 bg-card border-t border-border">
        <nav className="container mx-auto h-[90px] flex justify-between items-center">
          <div className="flex justify-around items-center flex-1">
            <Link href="/dashboard" passHref>
              <Button
                variant="ghost"
                className="group relative flex flex-col h-20 w-20 items-center justify-center space-y-1 rounded-full overflow-hidden"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                <div className="relative flex flex-col items-center justify-center space-y-1">
                  <Home className="h-6 w-6 text-primary transition-colors duration-300 group-hover:text-primary-foreground" />
                  <span className="text-xs font-medium text-muted-foreground transition-colors duration-300 group-hover:text-primary-foreground">Início</span>
                </div>
              </Button>
            </Link>
            <Link href="/translator" passHref>
              <Button
                variant="ghost"
                className="group relative flex flex-col h-20 w-20 items-center justify-center space-y-1 rounded-full overflow-hidden"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                <div className="relative flex flex-col items-center justify-center space-y-1">
                  <Languages className="h-6 w-6 text-primary transition-colors duration-300 group-hover:text-primary-foreground" />
                  <span className="text-xs font-medium text-muted-foreground transition-colors duration-300 group-hover:text-primary-foreground">Tradutor</span>
                </div>
              </Button>
            </Link>
          </div>

          <div className="relative -top-8">
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
            <Link href="/achievements" passHref>
              <Button
                variant="ghost"
                className="group relative flex flex-col h-20 w-20 items-center justify-center space-y-1 rounded-full overflow-hidden"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                <div className="relative flex flex-col items-center justify-center space-y-1">
                  <Trophy className="h-6 w-6 text-primary transition-colors duration-300 group-hover:text-primary-foreground" />
                  <span className="text-xs font-medium text-muted-foreground transition-colors duration-300 group-hover:text-primary-foreground">Conquistas</span>
                </div>
              </Button>
            </Link>
            <Link href="/settings" passHref>
              <Button
                className="flex flex-col h-20 w-20 items-center justify-center space-y-1 rounded-full bg-gradient-to-r from-primary to-accent text-primary-foreground"
              >
                <Settings className="h-6 w-6" />
                <span className="text-xs font-medium">Config</span>
              </Button>
            </Link>
          </div>
        </nav>
      </footer>
    </div>
  );
}
