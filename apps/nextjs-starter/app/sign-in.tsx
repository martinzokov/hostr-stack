'use client';

type Props = {
  onSignIn: () => Promise<void>;
  disabled?: boolean;
};

export default function SignIn({ onSignIn, disabled = false }: Props) {
  return (
    <button className="primaryButton" disabled={disabled} onClick={() => void onSignIn()}>
      Sign in
    </button>
  );
}

