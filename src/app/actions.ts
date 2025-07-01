
'use server';

import { redirect } from 'next/navigation';
import { z } from 'zod';
import { authenticateUser } from '@/ai/flows/auth';

const loginSchema = z.object({
  username: z.string().min(1, 'Username is required.'),
  password: z.string().min(1, 'Password is required.'),
});

export async function loginAction(prevState: any, formData: FormData) {
  const parsed = loginSchema.safeParse(Object.fromEntries(formData.entries()));

  if (!parsed.success) {
    return { message: parsed.error.errors[0].message };
  }

  const { username, password } = parsed.data;

  try {
    const result = await authenticateUser({ username, password });
    
    if (result.success) {
      redirect(`/dashboard?username=${encodeURIComponent(username)}&password=${encodeURIComponent(password)}`);
    } else {
      return { message: result.message };
    }
  } catch (error) {
    return { message: 'An unexpected error occurred. Please try again.' };
  }
}
