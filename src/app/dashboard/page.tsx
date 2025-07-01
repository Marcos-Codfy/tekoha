'use client';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Home, Trophy, Languages, Settings, User } from 'lucide-react';
import Link from 'next/link';
import Image from 'next/image';

export default function DashboardPage() {
  return (
    <div className="flex flex-col min-h-screen bg-background">
      <main className="flex-1 p-6 pb-24 space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>Bem-vindo(a)!</CardTitle>
            <CardDescription className="text-muted-foreground">
              Explore as maravilhas da língua Tupi-Guarani. Escolha seu nível e comece a aprender!
            </CardDescription>
          </CardHeader>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Níveis de Aprendizagem</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <Button size="lg" className="w-full h-14">Iniciante</Button>
                <Button size="lg" className="w-full h-14">Intermediário</Button>
              </div>
              <Button size="lg" className="w-full h-14">Avançado</Button>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Seu Perfil</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <Avatar className="h-12 w-12">
                   <AvatarFallback>
                    <User className="h-6 w-6" />
                  </AvatarFallback>
                </Avatar>
                <div>
                  <p className="font-semibold">Professor</p>
                  <p className="text-sm text-muted-foreground">Perfil selecionado</p>
                </div>
              </div>
              <Button variant="outline">Trocar Perfil</Button>
            </div>
          </CardContent>
        </Card>
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
                <Languages className="h-6 w-6" />
                <span className="text-xs font-medium">Tradutor</span>
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
            <Link href="#" passHref>
              <Button variant="ghost" className="flex flex-col h-auto p-3 space-y-1 rounded-xl text-muted-foreground">
                <Trophy className="h-6 w-6" />
                <span className="text-xs font-medium">Conquistas</span>
              </Button>
            </Link>
            <Link href="#" passHref>
              <Button variant="ghost" className="flex flex-col h-auto p-3 space-y-1 rounded-xl text-muted-foreground">
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
