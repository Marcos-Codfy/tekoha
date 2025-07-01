'use client';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Home, Trophy, Languages, Settings, ArrowRightLeft, Mic, Volume2, ChevronLeft } from 'lucide-react';
import Link from 'next/link';
import Image from 'next/image';
import { useState } from 'react';

export default function TranslatorPage() {
  const suggestions = ["kunhã poranga", "nde porã", "xe py'a pe", "paranã", "îaguara", "ara porã", "tetama", "purakĩ"];
  const [sourceLang, setSourceLang] = useState('Tupi');
  const [targetLang, setTargetLang] = useState('Pt');
  const [translation, setTranslation] = useState('');

  const handleSwapLanguages = () => {
    const newSource = targetLang;
    const newTarget = sourceLang;
    setSourceLang(newSource);
    setTargetLang(newTarget);
  };

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
      
      <main className="flex-1 flex flex-col p-4 md:p-6 space-y-6 pb-24">
        <header className="flex items-center justify-between">
          <Link href="/dashboard" passHref>
            <Button variant="ghost" size="icon" className="rounded-full">
              <ChevronLeft className="h-6 w-6" />
            </Button>
          </Link>
          <h1 className="text-xl font-bold">Tradutor</h1>
          <Button variant="outline" className="rounded-full" onClick={handleSwapLanguages}>
            <span>{sourceLang}</span>
            <ArrowRightLeft className="h-4 w-4 mx-2" />
            <span>{targetLang}</span>
          </Button>
        </header>

        <div className="flex-1 flex flex-col gap-4">
          <div className="rounded-lg bg-gradient-to-r from-primary to-accent p-[1px] shadow-lg flex-1 flex flex-col">
            <Card className="border-none h-full flex flex-col">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-base font-medium">Texto em {sourceLang}</CardTitle>
                <Button variant="ghost" size="icon" className="rounded-full">
                  <Mic className="h-5 w-5" />
                </Button>
              </CardHeader>
              <CardContent className="flex-1 p-4 pt-0">
                <Textarea placeholder="Digite o texto aqui..." className="h-full resize-none border-none focus-visible:ring-0 bg-transparent text-lg" />
              </CardContent>
            </Card>
          </div>

          <div className="rounded-lg bg-gradient-to-r from-primary to-accent p-[1px] shadow-lg flex-1 flex flex-col">
            <Card className="border-none h-full flex flex-col">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-base font-medium">Tradução para {targetLang}</CardTitle>
                 <Button variant="ghost" size="icon" className="rounded-full">
                  <Volume2 className="h-5 w-5" />
                </Button>
              </CardHeader>
              <CardContent className="flex-1 p-4 pt-0">
                 <div className="h-full w-full p-2 resize-none border-none text-lg text-muted-foreground">
                    {translation || "A tradução irá aparecer aqui..."}
                </div>
              </CardContent>
            </Card>
          </div>
        </div>

        <Button size="lg" className="w-full bg-accent hover:bg-accent/90 text-accent-foreground font-bold text-lg py-6">
          <Languages className="mr-2 h-5 w-5" />
          Traduzir
        </Button>

        <div>
          <h3 className="text-sm font-medium text-muted-foreground mb-2">Sugestões:</h3>
          <div className="flex flex-wrap gap-2">
            {suggestions.map((suggestion) => (
              <Badge key={suggestion} variant="secondary" className="cursor-pointer hover:bg-accent/20 px-3 py-1 text-sm">
                {suggestion}
              </Badge>
            ))}
          </div>
        </div>
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
            <Link href="/translator" passHref>
              <Button className="flex flex-col h-auto p-3 space-y-1 rounded-xl">
                <Languages className="h-6 w-6" stroke="url(#icon-gradient)" />
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
            <Link href="/achievements" passHref>
              <Button variant="ghost" className="flex flex-col h-auto p-3 space-y-1 rounded-xl">
                <Trophy className="h-6 w-6" stroke="url(#icon-gradient)" />
                <span className="text-xs font-medium text-muted-foreground">Conquistas</span>
              </Button>
            </Link>
            <Link href="/settings" passHref>
              <Button variant="ghost" className="flex flex-col h-auto p-3 space-y-1 rounded-xl">
                <Settings className="h-6 w-6" stroke="url(#icon-gradient)" />
                <span className="text-xs font-medium text-muted-foreground">Config</span>
              </Button>
            </Link>
          </div>
        </nav>
      </footer>
    </div>
  );
}
