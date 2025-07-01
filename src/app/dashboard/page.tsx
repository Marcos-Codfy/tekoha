'use client';

import { useSearchParams } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { CheckCircle, ShieldAlert } from 'lucide-react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Suspense } from 'react';

function DashboardContent() {
  const searchParams = useSearchParams();
  const username = searchParams.get('username');
  const password = searchParams.get('password');

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-4 animate-in fade-in-0 zoom-in-95 duration-500">
      <Card className="w-full max-w-md">
        <CardHeader className="items-center text-center">
          <CheckCircle className="h-16 w-16 text-green-500 mb-4" />
          <CardTitle className="text-2xl font-headline">Authentication Successful</CardTitle>
          <CardDescription>You have been successfully logged in.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="space-y-4 rounded-lg border bg-card p-4">
              <h3 className="font-semibold">Logged in with:</h3>
              <p className="text-sm"><strong>Username:</strong> {username}</p>
              <p className="text-sm"><strong>Password:</strong> <span className="font-mono bg-muted p-1 rounded-md">{password}</span></p>
          </div>
          <div className="flex items-start space-x-3 rounded-lg border border-destructive/50 p-4 text-destructive">
            <ShieldAlert className="h-5 w-5 mt-0.5 flex-shrink-0" />
            <div className="flex-1">
              <h4 className="font-semibold">Security Warning</h4>
              <p className="text-sm text-destructive/90">
                This information is displayed for demonstration purposes only. In a real-world application, never display or transmit passwords in plain text.
              </p>
            </div>
          </div>
          <Button asChild className="w-full bg-primary hover:bg-primary/90">
            <Link href="/">Log out</Link>
          </Button>
        </CardContent>
      </Card>
    </main>
  );
}

export default function DashboardPage() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <DashboardContent />
    </Suspense>
  )
}
