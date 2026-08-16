# JP 1.4.0 transport observations

This document records local, loopback-only runtime observations for the verified
JP client adapter. It does not rely on a live official service response.

## Client baseline

- Client: `blueoath/blueoath/blueoath.exe`
- `GameAssembly.dll` SHA-256:
  `8AEE607813A759E047D81C2428990609322DE072437DD4597F80E8E3FAD1D404`
- `UnityPlayer.dll` SHA-256:
  `88C45E6394C4C42F6698319C9B85D29C1AB461F8EBD6284CA9EE931F2050D63D`
- Capture date: 2026-08-13 (Asia/Hong_Kong)
- Redirect target: `127.0.0.1:19090`

## Confirmed transport families

The first application bytes are TLS ClientHello records, not raw protobuf or
the temporary length-prefixed JSON protocol currently implemented by
`BlueOath.Server`.

| SNI / host | First bytes | Classification | Observed retry pattern |
| --- | --- | --- | --- |
| `mapijpshipgirl.blueoath.com` | `16 03 03 00 C1` | TLS ClientHello (TLS 1.2 record) | approximately 10 seconds |
| `haina.blueoath.com` | `16 03 03 00 C1` | TLS ClientHello (TLS 1.2 record) | approximately 5 seconds |
| `cdp.cloud.unity3d.com:443` | `CONNECT ... HTTP/1.1` | Unity telemetry/proxy traffic | non-game traffic |

Each captured game ClientHello was 198 bytes. The SNI parser extracted both
game hostnames repeatedly, which confirms that a single forced local port can
still route the initial TLS traffic by SNI.

Capture fixtures are stored under:

`runtime/captures/jp-first-packet-20260813-02/`

## Consequences for the local server

1. Add a loopback TLS front end before implementing the real application
   protocol.
2. Route connections by ClientHello SNI so account/bootstrap traffic and game
   API traffic remain independent.
3. Exclude or explicitly reject unrelated Unity telemetry `CONNECT` traffic.
4. Determine whether the client trusts a local development CA, uses a bundled
   CA, or pins the server certificate before attempting HTTP/API decoding.
5. Only after a successful local TLS handshake should decrypted request bodies
   be classified as HTTP, protobuf, or a custom framing protocol.

No conclusion about protobuf message layout can be drawn from the encrypted
ClientHello-only captures.

## Local certificate probe

A second loopback-only probe used an OpenSSL TLS 1.2 server with a short-lived,
self-signed certificate whose SAN covered the two observed game hostnames. The
certificate and private key were generated in the capture directory and deleted
when the probe exited; neither was installed in a Windows certificate store.

For every connection, OpenSSL reached this sequence:

```text
read client hello
write server hello
write certificate
write key exchange
write server done
read warning close_notify
```

The client never sent a Finished message or application data. This repeatable
result confirms that the JP client does not accept the untrusted local probe
certificate. Evidence is stored under:

`runtime/captures/jp-tls-openssl-20260813-01/`

The next reverse-engineering target is therefore the client certificate
validation boundary (`CertificateHandler.ValidateCertificate` or the
UnityPlayer/libcurl equivalent). Any local-mode validation override must be
version-specific and enabled only when all of these conditions hold:

- the verified JP `GameAssembly.dll` hash matches;
- redirect/local mode is explicitly enabled;
- the connected peer is loopback;
- SNI is one of the explicitly configured local game hostnames.

It must not disable certificate validation globally or affect original mode.

## Certificate validation target selection

The JP v24 metadata type table was parsed as 11,582 records. It contains the
framework type `UnityEngine.Networking.CertificateHandler`, but no named game
type that appears to derive from or specialize it. PE imports also show that
UnityPlayer's libcurl/OpenSSL implementation is statically linked; there is no
imported `SSL_get_verify_result`, `X509_verify_cert`, or `curl_easy_setopt`
slot available for a narrow IAT hook.

Static analysis of the verified `UnityPlayer.dll` build (SHA-256
`88C45E6394C4C42F6698319C9B85D29C1AB461F8EBD6284CA9EE931F2050D63D`) located
the certificate verification chain inside the statically linked UnityTLS
component. The JP and CN clients ship the **byte-identical** `UnityPlayer.dll`
(same SHA-256 and size 17 929 672), so one version-specific patch covers both.

### Verification chain (all RVAs are image-relative, image base `0x10000000`)

1. Handshake state machine calls the verify wrapper at `0xE320D0`
   (`call 0xE320D0` at `0xE3196B`; the return is tested by `test eax, eax` /
   `jne` at `0xE31973` — any non-zero result aborts the handshake).
2. The wrapper calls the UnityTLS interface through the global pointer
   `0x11141490` (set by `mov [0x11141490], eax` at `0xE315C0`):
   - `interface->+0x10` = `0x8E0B30` (returns a 16-byte cert result struct);
   - `interface->+0x74` = `0x8E1460` (the verify function; returns the
     mbedTLS x509 verify flags into `ebx`).
3. The default interface struct is built at `0x8E0B90` and stored at
   `0x110D2660`.
4. `0x8E1460` performs the actual verification via
   `mbedtls_x509_crt_verify` (`call 0x10E07250` at `0x8E1511`) and returns the
   stored flags with `mov eax, [edi+0x34]` at `0x8E1573`.
5. The wrapper decides success/failure at `0xE32125`
   (`test ebx, ebx; je 0xE32293` — success requires the flag mask to be zero).

The flag bits match mbedTLS exactly: `0x01` EXPIRED, `0x02` REVOKED,
`0x04` CN_MISMATCH, `0x08` NOT_TRUSTED; UnityTLS adds `0x10000..0x8000000`
USER_ERROR1..8 and UNKNOWN_ERROR. A self-signed loopback certificate therefore
fails with exactly `NOT_TRUSTED (0x08)` once hostname and validity pass.

### Why the earlier patch did not work

The `TryApplyUnityTlsPatch` hook patched `test bl, 0x08` at `0xE32166`. That
instruction is inside the **error-message logging** block ("Cert verify failed:
UNITYTLS_X509VERIFY_FLAG_NOT_TRUSTED"), which runs *after* the pass/fail
decision at `0xE32125`. Changing it only suppresses the log line; it never
changes the returned error, so the client still rejected the local certificate.

### Correct patch point

Mask the `NOT_TRUSTED` bit out of the flags at the source, in the interface
verify function return, `0x8E1573`:

```text
original:  8B 47 34 5F 5E 5D C3          mov eax,[edi+0x34]; pop edi; pop esi; pop ebp; ret
patched:   8B 47 34 83 E0 F7 5F 5E 5D C3  mov eax,[edi+0x34]; and eax,0xFFFFFFF7; pop edi; pop esi; pop ebp; ret
```

The inserted `and eax, 0xFFFFFFF7` clears bit 3 (NOT_TRUSTED) while leaving
EXPIRED/CN_MISMATCH/REVOKED and the UnityTLS USER_ERROR bits intact, and fits
into the six-byte `int3` padding at `0x8E157A..0x8E157F`. Verified byte
signature to gate the patch: `8B 47 34 5F 5E 5D C3` at `0x8E1573`.

This is narrower than the log-line patch and satisfies the earlier rule: it
only affects the NOT_TRUSTED bit, and remains gated on the verified
`UnityPlayer.dll` hash plus explicit local mode plus loopback plus configured
SNI.

### Runtime confirmation

A loopback-only diagnostic (a detour at `0x8E1460` that logs the call count)
confirms that the UnityTLS x509 verify path **is** exercised by the live JP
client: it observed 16+ `unitytls x509 verify called` events, all with caller
`UnityPlayer.dll+0xE32112` — the return address after `call [0x11141490+0x74]`
inside the verify wrapper at `0xE320D0`, matching the static call graph above.
This confirms the earlier log-line patch at `0xE32166` never affected the
pass/fail decision, and that the `0x8E1573` mask is the correct, exercised
patch point. The observed SDK bootstrap HTTP traffic (`/phone/switch/getstate`,
`/sdk/gettime`, `/phone/applereview/`, `/phone/getPlData/getPlData`, `/c.gif`)
is served by libcurl in `new_sdk.dll`/`sdk_ui_win32xx.dll` and is a separate
path from the UnityTLS game-API connections.
