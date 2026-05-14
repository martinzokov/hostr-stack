'use client';

type Props = {
  onSignOut: () => Promise<void>;
};

export default function SignOut({ onSignOut }: Props) {
  return (
    <button className="secondaryButton" onClick={() => void onSignOut()}>
      Sign out
    </button>
  );
}

