# Publicar Blockfall en la App Store — sin Mac

Se compila en las máquinas macOS de GitHub Actions. El flujo está en
[`.github/workflows/ios.yml`](../.github/workflows/ios.yml) y se lanza a mano.

⚠️ **Nada de lo de esta página está probado.** No hay forma de compilar ni
ejecutar iOS desde Windows, así que todo lo que sigue está escrito con cuidado
pero **sin verificar**. Es normal que la primera compilación falle una o dos
veces; los errores de firma de Apple son crípticos pero se resuelven.

---

## Lo que ya está hecho

- Proyecto iOS con Bundle ID `com.cusme.blockfall`
- Iconos generados
- Solo orientación vertical
- `Info.plist` con AdMob, permiso de seguimiento y redes SKAdNetwork
- Petición de App Tracking Transparency antes de arrancar los anuncios
- Flujo de GitHub Actions
- Todo el código del juego: motor, ranking, música, traducciones

## Lo que falta y depende de ti

### 1. Firebase para iOS
Consola de Firebase → proyecto Blockfall → **Agregar app** → iOS →
Bundle ID `com.cusme.blockfall`.

Del `GoogleService-Info.plist` que te dé, pásame:
`API_KEY`, `GOOGLE_APP_ID`, `REVERSED_CLIENT_ID` y `CLIENT_ID`.

### 2. AdMob para iOS
AdMob → **Agregar aplicación** → iOS. Crea tres bloques: banner, intersticial
y bonificado. Pásame el **App ID** (con `~`) y los tres IDs de bloque.

### 3. Apple
En `developer.apple.com`:

- **Identifiers** → nuevo App ID `com.cusme.blockfall`
- **Certificates** → certificado de *Apple Distribution* → descargar
  → convertir a `.p12` (se puede desde la web con Llavero de un Mac, o
  generando la CSR con OpenSSL en Windows)
- **Profiles** → perfil de *App Store* para ese App ID → descargar
- Anota tu **Team ID** (10 caracteres, arriba a la derecha)

En `appstoreconnect.apple.com`:

- **Mis apps** → nueva app con ese Bundle ID, nombre **Blockfall**
- **Usuarios y acceso → Integraciones → App Store Connect API** → generar clave
  con permiso *App Manager*. Guarda el `.p8`: **solo se descarga una vez**.
  Anota el *Issuer ID* y el *Key ID*.

### 4. Secretos en GitHub
Repositorio → *Settings → Secrets and variables → Actions*:

| Secreto | De dónde sale |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | El `.p12` en base64 |
| `P12_PASSWORD` | La contraseña que le pusiste al `.p12` |
| `PROVISIONING_PROFILE_BASE64` | El `.mobileprovision` en base64 |
| `APPLE_TEAM_ID` | developer.apple.com |
| `APPSTORE_ISSUER_ID` | App Store Connect → API |
| `APPSTORE_KEY_ID` | App Store Connect → API |
| `APPSTORE_PRIVATE_KEY` | Contenido íntegro del `.p8` |

Para pasar un archivo a base64 en PowerShell:

```
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\ruta\cert.p12")) | Set-Clipboard
```

---

## Cómo lanzar la compilación

GitHub → pestaña **Actions** → *iOS* → **Run workflow**.

Tarda unos 15 minutos. Al terminar deja el `.ipa` como artefacto descargable y,
si dejaste marcada la casilla, lo sube a TestFlight.

**Consumo de minutos:** una compilación de 15 minutos gasta unos 150 de los
2.000 mensuales, porque macOS cuenta x10. Salen unas 13 al mes.

---

## Diferencias de la revisión de Apple

Es bastante más estricta que la de Google y tarda de 1 a 3 días:

- **Revisan a mano.** Una persona juega tu app. Si algo se cae, lo verán.
- **Rechazan las apps que parecen plantilla o aportan poco.** Blockfall tiene
  cuatro modos, ranking online y temas, así que va sobrado, pero conviene que
  la ficha lo deje claro.
- **El permiso de seguimiento tiene que estar bien.** Si pides el
  identificador sin mostrar el diálogo de ATT, rechazo directo.
- **La política de privacidad es obligatoria** y ya la tienes publicada.
- **Etiquetas de privacidad**: hay que rellenar en App Store Connect un
  cuestionario parecido al de Google. Sirve la misma tabla que usamos para
  Play.
- **Ni una mención a Tetris**, igual que en Google.
- Si añades la suscripción, Apple exige enlaces visibles a los términos y a la
  política, y un botón de **restaurar compras**.
