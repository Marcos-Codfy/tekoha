'use client';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardFooter } from '@/components/ui/card';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Home, Trophy, Languages, Settings, ArrowRightLeft, Mic, Volume2, ChevronLeft } from 'lucide-react';
import Link from 'next/link';
import Image from 'next/image';
import { useState } from 'react';

const ptToTupi: Record<string, string> = {
  'bom dia': 'ara porã',
  'água boa': 'y porã',
  'eu te amo': 'xe ro-payxu',
  'obrigado': 'aguyjewete',
  'floresta': 'kaá',
  'pássaro': 'guyrá',
  'família': 'tetama',
  'música': 'purakĩ',
};

const tupiToPt: Record<string, string> = Object.fromEntries(
  Object.entries(ptToTupi).map(([k, v]) => [v, k])
);

export default function TranslatorPage() {
  const [sourceLang, setSourceLang] = useState('Português');
  const [targetLang, setTargetLang] = useState('Tupi');
  const [sourceText, setSourceText] = useState('');
  const [translation, setTranslation] = useState('');
  
  const suggestions = sourceLang === 'Tupi' ? Object.keys(tupiToPt) : Object.keys(ptToTupi);

  const handleSwapLanguages = () => {
    const newSource = targetLang;
    const newTarget = sourceLang;
    setSourceLang(newSource);
    setTargetLang(newTarget);
    const newSourceText = translation;
    const newTranslation = sourceText;
    setSourceText(newSourceText);
    setTranslation(newTranslation);
  };

  const handleSuggestionClick = (suggestion: string) => {
    setSourceText(suggestion);
  };

  const handleTranslate = () => {
    const normalizedText = sourceText.toLowerCase().trim();
    if (!normalizedText) {
      setTranslation('');
      return;
    }

    let result = '';
    if (sourceLang === 'Português') {
      result = ptToTupi[normalizedText];
    } else {
      result = tupiToPt[normalizedText];
    }

    setTranslation(result || 'Tradução não encontrada.');
  };


  return (
    <div className="flex flex-col min-h-screen bg-background">
      <main className="flex-1 p-6 pb-24 space-y-8">
        <div className="flex items-center justify-between">
            <Link href="/dashboard" passHref>
                <Button variant="outline" size="icon" className="group relative rounded-full overflow-hidden bg-card hover:bg-card">
                  <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                  <div className="relative flex items-center justify-center">
                    <ChevronLeft className="h-6 w-6 text-primary transition-colors duration-300 group-hover:text-primary-foreground" />
                  </div>
                </Button>
            </Link>
            <h1 className="text-xl font-bold">Tradutor</h1>
            <Button variant="outline" className="group relative rounded-full overflow-hidden bg-card hover:bg-card" onClick={handleSwapLanguages}>
                <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                <div className="relative flex items-center justify-center gap-2 px-4 py-2">
                    <span className="font-medium text-card-foreground transition-colors duration-300 group-hover:text-primary-foreground">{sourceLang}</span>
                    <ArrowRightLeft className="h-4 w-4 text-primary transition-colors duration-300 group-hover:text-primary-foreground" />
                    <span className="font-medium text-card-foreground transition-colors duration-300 group-hover:text-primary-foreground">{targetLang}</span>
                </div>
            </Button>
        </div>

        <div className="rounded-lg bg-gradient-to-r from-primary to-accent p-[1px] shadow-lg">
          <Card className="border-none">
            <CardContent className="p-6 space-y-4">
              <div className="grid gap-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-muted-foreground">{sourceLang}</span>
                  <Button variant="outline" size="icon" className="group relative rounded-full overflow-hidden bg-card hover:bg-card">
                    <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                    <div className="relative flex items-center justify-center">
                      <Mic className="h-5 w-5 text-primary transition-colors duration-300 group-hover:text-primary-foreground" />
                    </div>
                  </Button>
                </div>
                <Textarea 
                  placeholder="Digite o texto aqui..." 
                  className="h-32 resize-none bg-background border border-input focus-visible:ring-1 focus-visible:ring-ring text-base"
                  value={sourceText}
                  onChange={(e) => setSourceText(e.target.value)}
                />
              </div>
              
              <Separator />

              <div className="grid gap-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-muted-foreground">{targetLang}</span>
                  <Button variant="outline" size="icon" className="group relative rounded-full overflow-hidden bg-card hover:bg-card">
                    <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                    <div className="relative flex items-center justify-center">
                      <Volume2 className="h-5 w-5 text-primary transition-colors duration-300 group-hover:text-primary-foreground" />
                    </div>
                  </Button>
                </div>
                <div className="h-32 w-full rounded-md border border-input bg-background p-3 text-base text-muted-foreground overflow-auto">
                    {translation || "A tradução irá aparecer aqui..."}
                </div>
              </div>

            </CardContent>
            <CardFooter className="pt-0">
                <Button
                  size="lg"
                  variant="outline"
                  className="group relative w-full overflow-hidden bg-card text-center hover:bg-card"
                  onClick={handleTranslate}
                >
                    <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
                    <div className="relative flex items-center justify-center gap-2">
                        <Languages className="mr-2 h-5 w-5 text-primary transition-colors duration-300 group-hover:text-primary-foreground" />
                        <span className="font-semibold text-base text-card-foreground transition-colors duration-300 group-hover:text-primary-foreground">
                            Traduzir
                        </span>
                    </div>
                </Button>
            </CardFooter>
          </Card>
        </div>

        <div className="rounded-lg bg-gradient-to-r from-primary to-accent p-[1px] shadow-lg">
          <Card className="border-none">
            <CardHeader>
              <CardTitle>Sugestões</CardTitle>
            </CardHeader>
            <CardContent className="pt-0">
              <div className="flex flex-wrap gap-2">
                {suggestions.map((suggestion) => (
                  <Badge 
                    key={suggestion} 
                    variant="secondary" 
                    className="cursor-pointer hover:bg-accent/20 px-3 py-1 text-sm"
                    onClick={() => handleSuggestionClick(suggestion)}
                  >
                    {suggestion}
                  </Badge>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </main>

      <footer className="fixed bottom-0 left-0 right-0 bg-card border-t border-border">
        <nav className="container mx-auto h-20 flex justify-between items-center">
          <div className="flex justify-around items-center flex-1">
            <Link href="/dashboard" passHref>
              <Button
                variant="ghost"
                className="group relative flex flex-col h-16 w-16 items-center justify-center space-y-1 rounded-full overflow-hidden"
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
                className="flex flex-col h-16 w-16 items-center justify-center space-y-1 rounded-full bg-gradient-to-r from-primary to-accent text-primary-foreground"
              >
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
            <Link href="/achievements" passHref>
              <Button
                variant="ghost"
                className="group relative flex flex-col h-16 w-16 items-center justify-center space-y-1 rounded-full overflow-hidden"
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
                className="group relative flex flex-col h-16 w-16 items-center justify-center space-y-1 rounded-full overflow-hidden"
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
