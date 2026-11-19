# Playbook IR - podejrzenie Qakbot (na podstawie pcapa Fazy 2)

## 1. Identyfikacja

- Host z nietypowym pobraniem HTTP (np. `.dat` z nieznanego IP), a potem HTTPS
  do adresów IP bez sensownego SNI.
- Dodatkowo: DNS do `www.openssl.org` / `api.ipify.org`, ruch na TCP/65400,
  wychodzący SMTP (EHLO) ze stacji końcowej.
- W AD: ustalić hostname (NBNS/DHCP/Kerberos) i konto użytkownika (AS-REQ/TGS).

## 2. Containment

- Izolacja hosta z sieci (VLAN kwarantanny / wyłączenie portu).
- Zablokować egress: IP payloadu, IP C2, TCP/65400, nieautoryzowany SMTP z klientów.
- Zabezpieczyć pcap / logi DHCP/DNS/proxy - nie nadpisywać.

## 3. Eradication

- Zbieranie artefaktów hostowych (prefetch, Run keys, scheduled tasks, DLL).
- Usunięcie binarek Qakbot / persystencji; reset hasła konta użytkownika.
- Przeskanowanie innych hostów w segmencie LAN pod kątem tych samych IOC.

## 4. Recovery

- Reimage albo czyszczenie + weryfikacja braku C2/SMTP.
- Przywrócenie do domeny, monitoring podwyższony 7-14 dni.
- Aktualizacja filtrów poczty (wektor wejściowy: złośliwy mail).

## 5. Lekcje

- Stacje końcowe nie powinny wysyłać SMTP bezpośrednio do Internetu.
- Alertować na HTTPS do gołych IP oraz na checki ipify/openssl w nietypowym kontekście.
- Pcap + tożsamość AD (user/host) to minimum do chronologii incydentu.
