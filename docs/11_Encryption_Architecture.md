# 11 — Encryption Architecture

## Purpose
Complete technical specification of the Signal Protocol implementation in SecureChat — X3DH key agreement, Double Ratchet Algorithm, key storage, session lifecycle, and recovery flows.

---

## 1. Signal Protocol Overview

The Signal Protocol provides:
- **Forward Secrecy:** Compromise of current keys does not expose past messages
- **Break-In Recovery:** Even if current keys are compromised, future messages are secure
- **Authentication:** Messages cannot be forged or replayed
- **Deniability:** Neither party can cryptographically prove they sent a message

### Components Used

| Component | Algorithm | Purpose |
|---|---|---|
| X3DH | Extended Triple Diffie-Hellman | Initial key agreement (session establishment) |
| Double Ratchet | Symmetric-key ratchet + DH ratchet | Per-message key derivation |
| Curve25519 | Elliptic Curve DH | Key pairs |
| AES-256-CBC | Symmetric encryption | Message encryption |
| HMAC-SHA256 | MAC | Message authentication |
| HKDF | Key derivation | Deriving message keys from ratchet state |

---

## 2. Key Types and Lifecycle

### 2.1 Identity Key Pair (IK)
- **Type:** Curve25519 long-term key pair
- **Lifetime:** Device lifetime (one key per user per device)
- **Private:** Never leaves device (flutter_secure_storage)
- **Public:** Published to Supabase `user_identity_keys` on registration
- **Purpose:** Proves identity in X3DH; used for authentication in all sessions

### 2.2 Signed Prekey (SPK)
- **Type:** Curve25519 medium-term key pair, signed by Identity Key
- **Lifetime:** 30 days (rotated monthly)
- **Private:** flutter_secure_storage
- **Public:** Published to Supabase `user_prekey_bundles` (is_one_time = false)
- **Purpose:** Allows async session initiation without both users online
- **Rotation:** New SPK generated every 30 days; old one retained for 7 days

### 2.3 One-Time Prekeys (OPK)
- **Type:** Curve25519 short-term key pairs (batch generated)
- **Lifetime:** Single use (consumed by one X3DH session)
- **Private:** flutter_secure_storage (batch)
- **Public:** Published to Supabase (100 at a time)
- **Purpose:** Provides additional forward secrecy in X3DH
- **Replenishment:** When supply drops below 10, new batch generated and uploaded

### 2.4 Ephemeral Key (EK)
- **Type:** Curve25519, generated per-session by initiator
- **Lifetime:** Used once for X3DH
- **Private:** Discarded after X3DH computation
- **Public:** Included in initial message header
- **Purpose:** Provides forward secrecy for session setup

---

## 3. X3DH Key Agreement (Session Establishment)

Performed once when User A initiates the first message to User B after pairing.

### 3.1 User B's Prekey Bundle (fetched by User A from Supabase)

```
PreKeyBundle {
  identity_key:       IK_B (public)
  signed_prekey_id:   SPK_B_id
  signed_prekey:      SPK_B (public)
  signature:          Sig(IK_B, SPK_B)    ← Verified by User A
  one_time_prekey_id: OPK_B_id
  one_time_prekey:    OPK_B (public)      ← May be absent if supply empty
}
```

### 3.2 User A's X3DH Computation

```
Step 1: Verify Sig(IK_B, SPK_B) — if invalid, abort
Step 2: Generate ephemeral key EK_A

Step 3: Compute 4 DH operations:
  DH1 = DH(IK_A, SPK_B)
  DH2 = DH(EK_A, IK_B)
  DH3 = DH(EK_A, SPK_B)
  DH4 = DH(EK_A, OPK_B)   ← Omitted if no OPK

Step 4: Derive master secret:
  MasterSecret = HKDF(DH1 || DH2 || DH3 || [DH4])

Step 5: Initialize Double Ratchet with MasterSecret
```

### 3.3 Initial Message to User B (X3DH Header)

The first message sent by User A includes a plaintext header:
```
{
  identity_key:       IK_A (public),
  ephemeral_key:      EK_A (public),
  one_time_prekey_id: OPK_B_id used,
  signed_prekey_id:   SPK_B_id used,
  message_ciphertext: [encrypted with derived session key]
}
```

### 3.4 User B's X3DH Computation (on receiving first message)

```
Step 1: Retrieve private keys: IK_B_priv, SPK_B_priv, OPK_B_priv

Step 2: Compute same 4 DH operations:
  DH1 = DH(SPK_B, IK_A)
  DH2 = DH(IK_B, EK_A)
  DH3 = DH(SPK_B, EK_A)
  DH4 = DH(OPK_B, EK_A)

Step 3: Derive same MasterSecret

Step 4: Delete OPK_B private key (one-time use complete)

Step 5: Initialize Double Ratchet with same MasterSecret → decrypt message
```

---

## 4. Double Ratchet Algorithm

After X3DH, all subsequent messages use the Double Ratchet.

### 4.1 Ratchet State

```
DoubleRatchetState {
  DHRatchetKeyPair:     current_dh_key_pair,
  DHRatchetPublicKey:   remote_dh_public_key,
  RootKey:              RK (32 bytes),
  ChainKeyS:            CKs (32 bytes, sending chain),
  ChainKeyR:            CKr (32 bytes, receiving chain),
  MessageCountS:        NS (int, sent message number),
  MessageCountR:        NR (int, received message number),
  PreviousChainCount:   PN (int),
  SkippedMessageKeys:   Map<(pubkey, msgnum), MessageKey>,
}
```

### 4.2 Sending a Message

```
Step 1: Advance sending chain key:
  MessageKey = HMAC-SHA256(CKs, 0x01)
  CKs_new    = HMAC-SHA256(CKs, 0x02)

Step 2: Encrypt message:
  Ciphertext = AES-256-CBC(MessageKey, plaintext)

Step 3: Create header:
  Header = { DH_public_key, NS, PN }

Step 4: Increment NS

Step 5: If DH ratchet step needed:
  Generate new DH key pair
  Advance root key: RK_new, CKs_new = KDF_RK(RK, DH(...))
  Send new DH public key in header
```

### 4.3 Receiving a Message

```
Step 1: Check if message is from a new DH ratchet step (new DH public key in header)
  If yes: advance DH ratchet, derive new receiving chain key

Step 2: Skip messages if needed (store skipped message keys)

Step 3: Advance receiving chain key:
  MessageKey = HMAC-SHA256(CKr, 0x01)
  CKr_new    = HMAC-SHA256(CKr, 0x02)

Step 4: Decrypt:
  Plaintext = AES-256-CBC-Decrypt(MessageKey, ciphertext)
```

### 4.4 Session State Persistence

After every send or receive, the full `DoubleRatchetState` is serialized and saved:
```
Key: secure_storage:signal_session_{pair_id}
Value: protobuf or JSON serialized DoubleRatchetState
```

This ensures session survives app restarts.

---

## 5. Media Encryption

Media files use AES-256-GCM (not Signal Protocol directly, as media is too large).

### 5.1 Encrypt Media

```
Step 1: Generate random 256-bit key (crypto.getRandomValues)
Step 2: Generate random 96-bit IV (crypto.getRandomValues)
Step 3: Encrypt file: ciphertext = AES-256-GCM(key, IV, plaintext_bytes)
Step 4: Package for message: { key, IV, storage_path }
Step 5: This package is the plaintext of a Signal Protocol message
Step 6: Signal Protocol encrypts this package → ciphertext sent to server
```

### 5.2 Decrypt Media

```
Step 1: Receive Signal Protocol message → decrypt → { key, IV, storage_path }
Step 2: Download encrypted blob from Supabase Storage using storage_path
Step 3: Decrypt: plaintext = AES-256-GCM-Decrypt(key, IV, ciphertext)
Step 4: Display or cache decrypted bytes
```

---

## 6. Session Recovery

### 6.1 Session Recovery After Reinstall

If the user reinstalls the app:
- Private keys are lost (unless backed up — intentionally NOT backed up for security)
- Existing Signal session is invalid
- Recovery flow:

```
Reinstall detected (no private keys in secure storage)
    │
    ▼
Generate new identity key pair, prekeys
    │
    ▼
Publish new public keys to Supabase (replace old)
    │
    ▼
Send "session reset" system message to partner
    │
    ▼
Partner app detects new identity key → initiates new X3DH
    │
    ▼
New session established → resume messaging
```

**Important:** Messages sent before reinstall cannot be decrypted. Past messages stored locally (before reinstall) on partner's device remain accessible.

### 6.2 Handling Out-of-Order Messages

The Double Ratchet inherently handles out-of-order messages via `SkippedMessageKeys`:
- Messages received out of order are decrypted using the stored skipped key
- Skipped keys retained for a maximum of 1000 messages or 7 days (whichever first)

---

## 7. Flutter Implementation

### 7.1 Library

Use `libsignal_protocol_dart` (or Dart bindings to libsignal via FFI if available).

```
signal_protocol_library: ^0.x.x
```

### 7.2 EncryptionService Interface

```
abstract class EncryptionService {
  Future<Either<EncryptionFailure, void>> generateKeyBundle(UserId userId);
  Future<Either<EncryptionFailure, PreKeyBundle>> fetchPartnerKeyBundle(UserId partnerId);
  Future<Either<EncryptionFailure, void>> initSession(PreKeyBundle partnerBundle);
  Future<Either<EncryptionFailure, Uint8List>> encrypt(String plaintext);
  Future<Either<EncryptionFailure, String>> decrypt(Uint8List ciphertext);
  Future<Either<EncryptionFailure, EncryptedMedia>> encryptMedia(Uint8List bytes);
  Future<Either<EncryptionFailure, Uint8List>> decryptMedia(EncryptedMedia encrypted);
}
```

### 7.3 Key Storage Keys (flutter_secure_storage)

| flutter_secure_storage Key | Content |
|---|---|
| `signal_identity_key_private` | Identity private key bytes (base64) |
| `signal_identity_key_public` | Identity public key bytes (base64) |
| `signal_registration_id` | Integer registration ID |
| `signal_signed_prekey_private_{id}` | Signed prekey private key |
| `signal_otp_private_{id}` | One-time prekey private key |
| `signal_session_{pair_id}` | Serialized Double Ratchet session state |

---

## 8. Security Properties Verification

| Property | Mechanism | Verification |
|---|---|---|
| Forward secrecy | Message keys derived and discarded | Compromise past session → future keys unaffected |
| Break-in recovery | DH ratchet every message | Compromise current keys → future keys change |
| Authentication | HMAC-SHA256 on every message | Tampered ciphertext fails MAC verification |
| Replay prevention | Message counter (NS/NR) in header | Replayed messages rejected (counter mismatch) |
| Deniability | HMAC (not signature) for message auth | Neither party can prove who sent what |
