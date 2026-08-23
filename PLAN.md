# Blockfall — Plan de desarrollo

**Nombre:** Blockfall · **Paquete:** `com.cusme.blockfall`
**Stack:** Flutter (Dart) · **Alcance:** completo con online + multijugador · **Publicación:** Google Play primero

---

## 1. Decisiones técnicas

| Tema | Decisión | Por qué |
|---|---|---|
| Framework | Flutter 3.x | Un código para Android e iOS |
| Render del tablero | `CustomPainter` + `Ticker` | Un Tetris son rectángulos en una grilla; no hace falta motor de juego |
| Estado | `flutter_riverpod` | Separa la lógica del juego de la UI, testeable |
| Persistencia local | `shared_preferences` (ajustes) + `hive` (récords) | Simple y offline |
| Audio | `audioplayers` | Música de fondo + efectos |
| Backend online | Firebase (Auth + Firestore) | Sin servidor propio; gratis al inicio |
| Tests | `flutter_test` sobre la lógica pura | La lógica no depende de la UI |

**Regla de oro:** la lógica del juego (`lib/game/`) no importa nada de Flutter. Así se puede testear sin emulador y reusar en el futuro.

---

## 2. Reglas del juego (especificación)

- Tablero: **10 columnas × 20 filas** visibles (+2 filas ocultas arriba para el spawn).
- 7 piezas: **I, O, T, S, Z, J, L**.
- **Rotación SRS** (Super Rotation System) con *wall kicks* — es el estándar moderno; sin esto el juego "se siente mal".
- **7-bag randomizer**: se barajan las 7 piezas y salen todas antes de repetir. Evita rachas injustas.
- **Hold**: guardar una pieza, un uso por pieza colocada.
- **Next**: mostrar las próximas 5 piezas.
- **Ghost piece**: sombra donde caerá la pieza.
- **Lock delay**: ~500 ms para mover/rotar antes de que la pieza se fije.
- **Soft drop** (bajar rápido) y **hard drop** (fijar al instante).

### Puntuación

| Acción | Puntos |
|---|---|
| 1 línea (Single) | 100 × nivel |
| 2 líneas (Double) | 300 × nivel |
| 3 líneas (Triple) | 500 × nivel |
| 4 líneas (Tetris) | 800 × nivel |
| T-Spin simple / doble | 800 / 1200 × nivel |
| Back-to-back (Tetris/T-Spin seguidos) | ×1.5 |
| Combo (líneas en turnos consecutivos) | 50 × combo × nivel |
| Soft drop / Hard drop | 1 / 2 por celda |

### Niveles y velocidad

- Sube un nivel cada **10 líneas**.
- Gravedad por nivel (tipo Tetris Guideline): nivel 1 ≈ 1000 ms por celda, nivel 5 ≈ 400 ms, nivel 10 ≈ 100 ms, nivel 15+ ≈ 1 celda por frame.

### Fin de partida

Game over cuando una pieza nueva no cabe en su posición de spawn (*block out*).

---

## 3. Controles táctiles

| Gesto | Acción |
|---|---|
| Deslizar izquierda/derecha | Mover pieza |
| Tocar | Rotar horario |
| Deslizar abajo | Soft drop |
| Deslizar abajo rápido | Hard drop |
| Deslizar arriba | Hold |
| Botón pausa (esquina) | Pausa |

Añadir **modo botones en pantalla** como alternativa en Ajustes: mucha gente prefiere D-pad virtual. Ambos esquemas configurables.

---

## 4. Pantallas

1. **Splash / carga**
2. **Menú principal** — Jugar, Modos, Ranking, Ajustes, Perfil
3. **Selección de modo** — Maratón, Sprint (40 líneas), Ultra (2 min), Zen (sin fin)
4. **Juego** — tablero, next, hold, puntuación, nivel, líneas, pausa
5. **Pausa** — reanudar, reiniciar, salir
6. **Game over** — puntuación, récord, reintentar, compartir
7. **Ranking** — pestañas Local / Global (global = Fase 4)
8. **Ajustes** — sonido, música, vibración, tema, esquema de control, idioma
9. **Perfil / login** — Fase 4

---

## 5. Estructura de carpetas

```
lib/
  main.dart
  game/                  # lógica pura, sin Flutter
    tetromino.dart       # las 7 piezas y sus rotaciones
    board.dart           # grilla, colisiones, limpiar líneas
    srs.dart             # tablas de wall kick
    bag.dart             # 7-bag randomizer
    scoring.dart         # puntos, niveles, combos
    game_engine.dart     # bucle: tick, spawn, lock, game over
  state/                 # providers de Riverpod
  ui/
    screens/             # una carpeta por pantalla
    widgets/             # BoardPainter, NextQueue, HoldBox, controles
  data/
    local_repository.dart
    remote_repository.dart   # Fase 4
  services/              # audio, vibración
assets/
  audio/  images/  fonts/
test/                    # tests de lib/game/
```

---

## 6. Fases de desarrollo

### Fase 0 — Preparar el entorno (1 día)

- Instalar **Flutter SDK** y **Android Studio** (incluye SDK de Android y emulador).
- `flutter doctor` hasta que todo salga en verde.
- Activar **Depuración USB** en tu teléfono Android para probar en dispositivo real.
- Crear el proyecto y un repositorio Git.

### Fase 1 — Motor del juego, sin interfaz (3–5 días)

Todo en `lib/game/`, verificado con tests:

1. Representar piezas y sus 4 rotaciones.
2. Tablero con detección de colisiones.
3. Gravedad, mover, rotar, lock.
4. Limpiar líneas y compactar.
5. 7-bag randomizer.
6. Rotación SRS con wall kicks.
7. Puntuación, niveles, combos, back-to-back.

**Hito:** los tests pasan y se puede simular una partida completa por consola.

### Fase 2 — Interfaz jugable (4–6 días)

1. Pintar el tablero con `CustomPainter`.
2. Conectar el bucle de juego con un `Ticker`.
3. Next, hold, ghost piece, HUD de puntuación.
4. Gestos táctiles + botones en pantalla.
5. Pausa y pantalla de game over.
6. Adaptar a distintos tamaños de pantalla y notch.

**Hito:** juego completo y jugable en tu teléfono.

### Fase 3 — Pulido y contenido local (4–6 días)

1. ✅ Sonidos y música, con opción de silenciar. Todo sintetizado por código en
   `tool/` — sin licencias de terceros. La música es una melodía **original**
   en la menor: usar «Korobéiniki» sería legal (es folclore de dominio
   público) pero delataría el juego como clon de Tetris.
2. Vibración al fijar pieza y al hacer Tetris.
3. Animaciones: destello de línea, sacudida, cuenta atrás 3-2-1.
4. Modos Sprint, Ultra y Zen.
5. Récords locales por modo.
6. Temas visuales (claro, oscuro, retro, neón).
7. ✅ Textos en español e inglés, con detección automática del idioma del
   teléfono y cambio manual en Ajustes.

**Cómo añadir un idioma nuevo:** copiar `lib/l10n/app_es.arb` a
`app_<código>.arb`, traducir los valores y ejecutar `flutter gen-l10n`. Añadir
después la opción en la sección Idioma de `settings_screen.dart`. No hay ni un
texto suelto por el código: todos salen de los `.arb`.

**Hito:** app que ya se siente un producto terminado.

### Fase 3.5 — Monetización ✅ implementada (con IDs de prueba)

**Anuncios (AdMob)**

| Formato | Dónde | Frecuencia |
|---|---|---|
| Banner | Menú, récords, ajustes y **pausa** | Siempre visible en esas pantallas |
| Banner | Partida en curso | **Nunca** |
| Intersticial | Tras el resultado del Game Over | Cada 3 partidas, mínimo 90 s entre uno y otro |
| Vídeo recompensado | Botón "Continuar" en el Game Over | **Una sola vez por partida** |

Reglas del revivir: despeja las 8 filas superiores, conserva puntos, nivel y
líneas. No se ofrece en Zen (no hay game over), en versus (rompería el duelo),
ni al completar un Sprint o un Ultra (eso es ganar, no perder). Si el jugador
cierra el vídeo antes de terminarlo, no revive **y no se le gasta el intento**.

**Suscripción sin anuncios — 1 USD/mes (pendiente, Fase 8)**

Ya existe el interruptor `isPremium` y todo el código lo respeta: al activarlo
desaparecen banners, intersticiales y se concede el revivir sin vídeo. Falta
conectarlo a Google Play Billing.

Cuentas: de 1 USD/mes Google se queda el 15% el primer millón anual, así que
quedan ~0,85 USD por suscriptor.

**IDs reales de AdMob — ya configurados (Android)**

- App ID: `ca-app-pub-9365652468083873~1544364533` → `AndroidManifest.xml`
- Banner: `ca-app-pub-9365652468083873/8443930324`
- Intersticial: `ca-app-pub-9365652468083873/2920035705`
- Bonificado: `ca-app-pub-9365652468083873/9231282864`

`useTestAds` está atado a `kDebugMode`: en depuración salen anuncios de prueba
y en release los reales, sin tener que acordarse de cambiar nada. iOS todavía
no tiene bloques creados; hasta entonces cae al de prueba y avisa en el log.

**Antes de publicar, obligatorio:**

1. ~~Poner los IDs reales~~ ✅ hecho.
2. Política de privacidad publicada en una URL (la exigen AdMob y Play).
3. Formulario de Seguridad de los Datos en Play Console declarando el uso del
   identificador de publicidad.
4. Clasificación de contenido indicando que la app muestra anuncios.
5. Vincular la app de AdMob con la ficha de Google Play una vez publicada.

⚠️ **Nunca pulsar los anuncios propios ni pedir a nadie que lo haga.** Google
lo detecta como tráfico inválido y cierra la cuenta de AdMob de forma
permanente, reteniendo lo pendiente de pago. Por eso todo el desarrollo va con
los bloques de prueba.

### Fase 4 — Online ✅ código completo, falta conectar la cuenta

1. ✅ Auth anónimo **y Google Sign-In**.

   Entrar con Google usa `linkWithCredential`, que **asciende la cuenta anónima
   conservando el mismo uid**: el historial no se pierde al iniciar sesión. Si
   esa cuenta de Google ya tenía historial de otro dispositivo, no se pueden
   fusionar los dos, así que se entra con el que ya existía y se avisa al
   jugador.

   Resuelve además el efecto del borrado automático de cuentas anónimas a los
   30 días de inactividad: quien entra con Google no lo sufre.

   El `serverClientId` que necesita google_sign_in es el cliente OAuth **web**
   del proyecto, no el de Android. Confundirlos es el fallo más habitual al
   montar esto.
2. ✅ Firestore: `leaderboards/{modo}/scores` con uid, nombre, puntos, líneas,
   nivel, duración y fecha **puesta por el servidor**.
3. ✅ Ranking con filtros hoy / semana / histórico, y pestaña por modo.
4. ✅ Reglas de seguridad en [firestore.rules](firestore.rules): lectura
   pública, escritura solo autenticada y a nombre propio, y **prohibido editar
   o borrar** (sin eso cualquiera podría vaciar el ranking ajeno).
5. ✅ Anti-trampas en dos capas, cliente y servidor, con las mismas reglas.
6. ✅ Cola offline: si no hay red la puntuación se guarda y sube al reconectar.
7. ✅ Degradación limpia: sin Firebase configurado el juego funciona igual y la
   pestaña Global avisa en vez de fallar.

**Pendiente (requiere la cuenta de Google del usuario):** crear el proyecto en
Firebase, rellenar los cuatro valores de
[firebase_options.dart](lib/firebase_options.dart), activar Auth anónimo, crear
Firestore y publicar las reglas.

Sobre el anti-trampas, con honestidad: frena a quien edita el APK sin
esforzarse, no a alguien decidido. Una puntuación alta pero plausible es
indistinguible de una real. Blindarlo exigiría enviar la secuencia de jugadas y
revalidar la partida en el servidor — un proyecto en sí mismo, que solo merece
la pena si el ranking llega a llenarse de basura.

Multijugador: ver Fase 7.

### Privacidad y formulario de Seguridad de los Datos

Política redactada en [PRIVACIDAD.md](PRIVACIDAD.md) y lista para publicar en
[hosting/privacidad.html](hosting/privacidad.html).

**Publicarla con Firebase Hosting** (gratis, y el proyecto ya existe):

```
npm install -g firebase-tools
firebase login
firebase deploy --only hosting
```

Queda en `https://blockfall-593.web.app/privacidad`.

**Cómo rellenar el formulario de Seguridad de los Datos de Play Console.**
Declarar de menos es motivo de rechazo o de retirada posterior:

| Tipo de dato | ¿Se recoge? | ¿Se comparte? | Finalidad | ¿Obligatorio? |
|---|---|---|---|---|
| ID de publicidad | Sí | Sí (Google) | Publicidad | Sí |
| ID de usuario (uid anónimo) | Sí | No | Funciones de la app | Sí |
| Nombre de jugador | Sí | No | Funciones de la app | No, opcional |
| Acciones en la app (puntuaciones) | Sí | No | Funciones de la app, analíticas | Sí |
| Info del dispositivo / IP | Sí | Sí (Google) | Publicidad | Sí |
| Ubicación, contactos, fotos, correo | No | — | — | — |

Además hay que marcar:

- Los datos se **cifran en tránsito** → Sí.
- Los usuarios pueden **solicitar la eliminación** de sus datos → Sí, por correo.
- Público objetivo: **mayores de 13 años** (no infantil). Si algún día se
  marcara como infantil, AdMob obligaría a desactivar los anuncios
  personalizados y cambiarían las reglas.

### Firma de la app ✅

La clave de subida está creada y el App Bundle se firma con ella.

- Almacén: `android/blockfall-upload.jks` · alias `blockfall`
- Configuración: `android/key.properties` (**no se sube al repositorio**)
- Titular: CN=Jhon Cusme · válida hasta enero de 2054
- **SHA-1 de la clave de subida:**
  `25:2D:65:71:5D:CE:78:82:1F:F9:1D:25:6A:26:26:30:33:F5:CF:08`
- SHA-256:
  `5E:E0:DE:39:A9:11:4C:89:BC:85:C5:3A:01:21:4D:0B:DB:CC:F8:B2:64:B5:40:15:09:10:6B:05:14:D0:33:A6`

Compilar el paquete para Play:

```
flutter build appbundle --release
```

Sale en `build/app/outputs/bundle/release/app-release.aab`.

⚠️ Copia de seguridad del `.jks` y de su contraseña en dos sitios distintos.
Con **Play App Signing** activado (viene marcado por defecto), perder esta
clave de subida es recuperable pidiendo un reinicio a Google, pero es un
trámite lento y conviene no llegar ahí.

**Las dos huellas SHA-1.** Con Play App Signing, Google firma la app publicada
con *su* clave, no con esta. Para que Google Sign-In funcione en producción hay
que registrar en Firebase **las dos huellas**: la de arriba y la que aparece en
Play Console → Integridad de la aplicación, disponible solo después de subir la
app por primera vez.

### Fase 5 — Publicar en Google Play ⏳ en revisión

Versión 1.0.0 enviada el 23 de agosto de 2026. Jugada y validada en un Samsung
real antes de enviarla.

Hecho: ficha en español, política de privacidad y página de eliminación de
datos publicadas en Firebase Hosting, `app-ads.txt`, mensaje de consentimiento
europeo configurado en AdMob, huella SHA-1 de subida registrada en Firebase.

Pendiente en cuanto se publique:

1. Vincular la app en AdMob con la ficha de Play (mientras figure como no
   publicada, AdMob limita el relleno y se gana menos).
2. AdMob → app-ads.txt → **Comprobar ahora**.
3. Añadir en Firebase la **segunda huella SHA-1**, la del certificado de firma
   de Google (Play Console → Integridad de la aplicación). Sin ella el inicio
   de sesión con Google falla para quien instale desde la tienda.
4. Añadir el idioma inglés a la ficha.

### Detalle de la publicación

1. Cuenta de Google Play Console (**25 USD, pago único**).
2. Icono, nombre, descripción, capturas (mínimo 2), gráfico destacado 1024×500.
3. Firma de la app (keystore) — **guarda ese archivo y su contraseña o pierdes la app**.
4. Compilar `flutter build appbundle --release`.
5. Política de privacidad (obligatoria si usas Firebase) y formulario de Seguridad de los Datos.
6. Prueba interna → producción. *(Tu cuenta no está sujeta al requisito de 12 testers / 14 días.)*

### Fase 8 — Suscripción sin anuncios (3–5 días)

1. Crear la suscripción `blockfall_sin_anuncios` a 1 USD/mes en Play Console.
2. Paquete `in_app_purchase`: comprar, restaurar y escuchar cambios.
3. La fuente de la verdad es Google Play, no el archivo local: al arrancar se
   consulta la tienda y se refresca la marca `isPremium`.
4. Pantalla de venta explicando qué incluye, y botón "Restaurar compra"
   (obligatorio: sin él Google rechaza la app).
5. Gestionar caducidad, reembolsos y periodo de gracia.

### Fase 7 — Multijugador en tiempo real (8–14 días)

Va **después** de la Fase 5, sobre una base ya publicada y estable.

- **Modo:** versus 1 contra 1 con *garbage* (las líneas que haces envían basura al rival). Es el multijugador clásico y el más divertido.
- **Transporte:** Firebase Realtime Database para emparejar + WebSocket propio para la partida. Firestore no sirve aquí: cobra por escritura y su latencia no da para tiempo real.
- **Modelo:** cada cliente simula su propio tablero y envía eventos (`pieza colocada`, `líneas enviadas`), no el estado completo. El rival se dibuja como miniatura.
- **Emparejamiento:** cola simple por rango de puntuación, con bots de relleno si no hay nadie conectado (importante al principio, cuando no hay jugadores).
- **Servidor:** Node.js con WebSocket en Cloud Run o Fly.io. **Este es el primer coste recurrente real:** ~5–15 USD/mes según jugadores.
- **Reconexión:** si un jugador se cae, 10 s de gracia y luego victoria por abandono.
- **Anti-trampas:** el servidor valida el ritmo de envío de basura; imposible confiar en el cliente.

Estimación: 8–14 días. Es, por sí solo, más trabajo que las fases 1 y 2 juntas.

### Fase 6 — iOS (más adelante)

El código Flutter ya sirve. Necesitarás: un **Mac** con Xcode, **Apple Developer Program (99 USD/año)**, adaptar iconos y notch, y pasar la revisión de App Store (más estricta que Google).

---

## 7. Riesgos y cómo evitarlos

| Riesgo | Mitigación |
|---|---|
| SRS y wall kicks son la parte difícil | Implementarlos en Fase 1 con tests, no improvisar en la UI |
| Los controles táctiles se sienten mal | Probar en teléfono real desde el primer día; ofrecer botones como alternativa |
| Ranking global con trampas | Validación en servidor + reglas de Firestore; asumir que es imperfecto |
| Marca registrada | **"Tetris" es marca registrada de The Tetris Company.** No uses ese nombre, ni el logo, ni el diseño de la app oficial. Elige un nombre propio (p. ej. "Blockfall", "Cascada") |
| Perder el keystore | Copia de seguridad en dos sitios antes de publicar |
| Abarcar demasiado | No empezar la Fase 4 hasta que la 3 esté cerrada |

---

## 8. Estimación

| Fase | Días (principiante, medio tiempo) |
|---|---|
| 0 Entorno | 1 |
| 1 Motor | 3–5 |
| 2 UI | 4–6 |
| 3 Pulido | 4–6 |
| 4 Online | 5–8 |
| 5 Publicación | 2–3 |
| **Total** | **~19–29 días de trabajo** |

## 9. Costes

| Concepto | Coste |
|---|---|
| Flutter, Android Studio | Gratis |
| Google Play Console | 25 USD, una vez |
| Firebase (plan Spark) | Gratis hasta cuotas generosas |
| Apple Developer (Fase 6) | 99 USD/año |
| Mac para iOS (Fase 6) | Hardware o Mac en la nube |

---

## Siguiente paso

Fase 0: instalar Flutter y Android Studio, y crear el esqueleto del proyecto.
