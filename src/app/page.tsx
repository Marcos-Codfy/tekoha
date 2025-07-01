import { LoginForm } from "@/components/login-form";

export default function Home() {
  return (
    <main className="flex min-h-screen w-full flex-col items-center justify-center p-4 gap-8">
      <h1 className="text-7xl font-bold tracking-widest bg-clip-text text-transparent bg-gradient-to-r from-primary to-accent">
        TEKOHÁ
      </h1>
      <LoginForm />
    </main>
  );
}
