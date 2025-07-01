'use client';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Home, Trophy, Languages, Settings, User, Crown, Feather, TrendingUp } from 'lucide-react';
import Link from 'next/link';
import Image from 'next/image';

export default function DashboardPage() {
  return (
    <div className="flex flex-col min-h-screen bg-background">
      <main className="flex-1 p-6 pb-24 space-y-8">
        <div className="rounded-lg bg-gradient-to-r from-primary to-accent p-[1px] shadow-lg">
          <Card className="border-none">
            <CardHeader className="text-center">
              <CardTitle>Bem-vindo(a)!</CardTitle>
              <CardDescription className="text-muted-foreground">
                Explore as maravilhas da língua Tupi-Guarani. Escolha seu nível e comece a aprender!
              </CardDescription>
            </CardHeader>
          </Card>
        </div>

        <div className="rounded-lg bg-gradient-to-r from-primary to-accent p-[1px] shadow-lg">
          <Card className="border-none">
            <CardHeader>
              <CardTitle>Níveis de Aprendizagem</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex flex-col space-y-3">
                <Button
                  variant="outline"
                  className="group relative h-auto w-full justify-start overflow-hidden bg-card p-4 text-left hover:bg-card"
                >
                  <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                  <div className="relative flex items-center gap-4">
                    <Feather className="h-6 w-6 text-primary transition-colors duration-300 group-hover:text-primary-foreground" />
                    <div className="transition-colors duration-300">
                      <p className="font-semibold text-base text-card-foreground group-hover:text-primary-foreground">Iniciante</p>
                      <p className="text-sm font-normal text-muted-foreground group-hover:text-primary-foreground/80">Comece sua jornada aqui.</p>
                    </div>
                  </div>
                </Button>
                <Button
                  variant="outline"
                  className="group relative h-auto w-full justify-start overflow-hidden bg-card p-4 text-left hover:bg-card"
                >
                  <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                  <div className="relative flex items-center gap-4">
                    <TrendingUp className="h-6 w-6 text-primary transition-colors duration-300 group-hover:text-primary-foreground" />
                    <div className="transition-colors duration-300">
                      <p className="font-semibold text-base text-card-foreground group-hover:text-primary-foreground">Intermediário</p>
                      <p className="text-sm font-normal text-muted-foreground group-hover:text-primary-foreground/80">Aprofunde seus conhecimentos.</p>
                    </div>
                  </div>
                </Button>
                <Button
                  variant="outline"
                  className="group relative h-auto w-full justify-start overflow-hidden bg-card p-4 text-left hover:bg-card"
                >
                  <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                  <div className="relative flex items-center gap-4">
                    <Crown className="h-6 w-6 text-primary transition-colors duration-300 group-hover:text-primary-foreground" />
                    <div className="transition-colors duration-300">
                      <p className="font-semibold text-base text-card-foreground group-hover:text-primary-foreground">Avançado</p>
                      <p className="text-sm font-normal text-muted-foreground group-hover:text-primary-foreground/80">Torne-se um mestre.</p>
                    </div>
                  </div>
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
        
        <div className="rounded-lg bg-gradient-to-r from-primary to-accent p-[1px] shadow-lg">
          <Card className="border-none">
            <CardHeader>
              <CardTitle>Seu Perfil</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <Avatar className="h-12 w-12">
                     <AvatarFallback>
                      <User className="h-6 w-6 text-primary" />
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <p className="font-semibold">Professor</p>
                    <p className="text-sm text-muted-foreground">Perfil selecionado</p>
                  </div>
                </div>
                <Button
                  variant="outline"
                  className="group relative h-auto overflow-hidden bg-card p-2 text-center hover:bg-card"
                >
                  <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                  <div className="relative flex items-center justify-center">
                    <span className="font-semibold text-sm text-card-foreground transition-colors duration-300 group-hover:text-primary-foreground">
                      Trocar Perfil
                    </span>
                  </div>
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </main>

      <footer className="fixed bottom-0 left-0 right-0 bg-card border-t border-border">
        <nav className="container mx-auto h-[90px] flex justify-between items-center">
          <div className="flex justify-around items-center flex-1">
            <Link href="/dashboard" passHref>
              <Button
                className="flex flex-col h-20 w-20 items-center justify-center space-y-1 rounded-full bg-gradient-to-r from-primary to-accent text-primary-foreground"
              >
                <Home className="h-6 w-6" />
                <span className="text-xs font-medium">Início</span>
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
                variant="ghost"
                className="group relative flex flex-col h-20 w-20 items-center justify-center space-y-1 rounded-full overflow-hidden"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                <div className="relative flex flex-col items-center justify-center space-y-1">
                  <Settings className="h-6 w-6 text-primary transition-colors duration-300 group-hover:text-primary-foreground" />
                  <span className="text-xs font-medium text-muted-foreground transition-colors duration-300 group-hover:text-primary-foreground">Config</span>
                </div>
              </Button>
            </Link>
          </div>
        </nav>
      </footer>
    </div>
  );
}
