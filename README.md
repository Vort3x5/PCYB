# PCYB — antena izotropowa 40dBi

## Faza 1 — Log4Shell (red)

```bash
nix develop
./scripts/fetch-vendor.sh
./scripts/setup-capture.sh
./scripts/run-full-lab.sh
```

## Faza 2 — analiza pcapa (blue)

Materiał od prowadzącej: `PCYB_Faza2_26Z_25.zip` (pcap Qakbot / nutmeg-station).

```bash
nix develop
unzip -o PCYB_Faza2_26Z_25.zip -d res/faza2-instructor
./scripts/run-faza2.sh
# wyniki: evidence/faza2/{detections,timeline,findings,...}
```

Dokumenty: `docs/raport-faza1.typ`, `docs/raport-faza2.typ`.
