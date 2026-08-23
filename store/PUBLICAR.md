# Publicar Blockfall en Google Play — guía paso a paso

Todo lo técnico está hecho. Lo que queda es rellenar la consola, y eso solo
puedes hacerlo tú porque va con tu cuenta.

**Archivo a subir:** `build/app/outputs/bundle/release/app-release.aab`
(59 MB, versión 1.0.0, firmado, targetSdk 36)

---

## Comprobación previa — ya verificada

| Requisito de Play | Estado |
|---|---|
| Formato App Bundle (.aab), no APK | ✅ |
| Firmado con clave propia, válida hasta 2054 | ✅ |
| `targetSdk` 36 (Play exige el nivel reciente) | ✅ |
| `minSdk` 24 | ✅ |
| Versión 1.0.0 (código 1) | ✅ |
| Política de privacidad en una URL pública | ✅ |
| Icono, gráfico destacado y capturas | ✅ |

---

## Antes de empezar: dos comprobaciones de la cuenta

1. **Verificación de identidad.** Play Console → *Configuración → Detalles de
   la cuenta de desarrollador*. Si aparece pendiente, complétala **ya**: hasta
   que no esté verificada, la app no se publica aunque la revisión salga bien.
   Suele ser lo que más retrasa una primera publicación.

2. **Requisito de pruebas cerradas.** Dijiste que tu cuenta no lo exige.
   Confírmalo en *Todas las aplicaciones → Crear aplicación*: si al llegar a
   producción te pide 12 testers durante 14 días, avísame y cambiamos el plan.

---

## Paso 1 — Crear la aplicación

Play Console → **Crear aplicación**

| Campo | Valor |
|---|---|
| Nombre | `Blockfall` |
| Idioma predeterminado | Español (Latinoamérica) |
| Tipo | **Juego** |
| ¿Gratis o de pago? | **Gratis** (no se puede cambiar a pago después) |

Acepta las declaraciones de directrices y de leyes de exportación.

---

## Paso 2 — «Contenido de la aplicación»

Es la sección donde se atasca casi todo el mundo. **Play no revisa nada hasta
que esté completa entera.** Ve una por una:

### Política de privacidad
```
https://blockfall-593.web.app/privacidad
```

### Acceso a la aplicación
→ *Todas las funciones están disponibles sin restricciones especiales.*
No hace falta cuenta para jugar, así que no des credenciales de prueba.

### Anuncios
→ **Sí, la app contiene anuncios.**

Omitir esto y que luego lo detecten es motivo de suspensión.

### Clasificación de contenido
Rellena el cuestionario. Para este juego:

- Violencia, sexo, lenguaje soez, drogas, apuestas → **No** a todo
- ¿Los usuarios pueden interactuar entre sí o compartir contenido? → **Sí**
  (el ranking muestra nombres escritos por los jugadores)
- ¿Comparte la ubicación del usuario? → No
- ¿Muestra anuncios? → **Sí**

Resultado esperado: apto para todos los públicos.

### Público objetivo y contenido
- Grupos de edad: **13-15, 16-17 y 18+**. No marques menores de 13: eso activa
  las normas de Google Play para familias y obligaría a desactivar los anuncios
  personalizados.
- ¿Va dirigida a niños? → **No**

### Seguridad de los datos
La parte más delicada. Declara **exactamente** esto:

| Dato | Se recoge | Se comparte | Finalidad | Obligatorio |
|---|---|---|---|---|
| ID de publicidad | Sí | Sí | Publicidad | Sí |
| ID de usuario | Sí | No | Funciones de la app | Sí |
| Nombre (el del ranking) | Sí | No | Funciones de la app | No |
| Dirección de correo | Sí | No | Funciones de la app | No |
| Interacciones en la app | Sí | No | Funciones de la app, analíticas | Sí |
| Info del dispositivo o IDs | Sí | Sí | Publicidad | Sí |

Y marca:
- Datos **cifrados en tránsito** → Sí
- Los usuarios pueden **solicitar la eliminación** → Sí

El correo aparece solo si el jugador inicia sesión con Google; por eso va como
opcional. Declararlo de menos es de las cosas que Google detecta y penaliza.

### Aplicaciones gubernamentales / finanzas / salud
→ No a todas.

---

## Paso 3 — Ficha principal de la tienda

*Crecimiento → Presencia en Play → Ficha principal de la tienda*

Copia los textos de [FICHA_PLAY.md](FICHA_PLAY.md). Recuerda: **la palabra
«Tetris» no puede aparecer en ningún campo.**

**Recursos gráficos:**

| Elemento | Archivo | Requisito |
|---|---|---|
| Icono | `assets/icon/icon.png` | 512×512 (Play redimensiona el de 1024) |
| Gráfico destacado | `store/feature_graphic.png` | 1024×500 |
| Capturas de teléfono | `store/screenshots/es_*.png` | mínimo 2, sube las 3 |

Añade después el idioma **inglés (Estados Unidos)** con los textos en inglés y
las capturas `en_*`. Duplica el alcance y no cuesta nada.

---

## Paso 4 — Subir la versión

*Producción → Crear nueva versión*

1. **Firma de aplicaciones de Google Play**: déjala activada. Google guarda la
   clave real y la tuya pasa a ser clave de subida, recuperable si se pierde.
2. Sube `app-release.aab`.
3. Nombre de la versión: `1.0.0`
4. Notas de la versión:

```
<es-419>
Primera versión de Blockfall.
Cuatro modos de juego, ranking global, cuatro temas y controles configurables.
</es-419>
<en-US>
First release of Blockfall.
Four game modes, global ranking, four themes and configurable controls.
</en-US>
```

5. **Países**: selecciona todos, salvo que quieras empezar solo por Ecuador.
6. Guardar → Revisar versión → **Iniciar lanzamiento a producción**.

---

## Paso 5 — Después de subir (importante, no lo saltes)

1. **Segunda huella SHA-1.** *Configuración → Integridad de la aplicación →
   Firma de apps*. Copia el **SHA-1 del certificado de firma de apps** (el de
   Google, distinto al tuyo) y añádelo en Firebase → Configuración del proyecto
   → tu app Android → Agregar huella digital.

   Sin esto, el inicio de sesión con Google funciona en tus pruebas y **falla
   para todo el que instale desde la tienda**.

2. **Vincular AdMob**: en AdMob, en la app Blockfall, enlázala con la ficha de
   Play. Mientras esté marcada como «no publicada», AdMob limita el relleno de
   anuncios y ganas menos.

3. Pon la URL de Play en la política de privacidad si quieres, y en AdMob.

---

## Cuánto tarda y qué la retrasa

**Nadie puede acelerar la revisión de Google.** No hay botón de prioridad ni
truco. Para una primera app de una cuenta nueva suele ir de unos días hasta un
par de semanas; Google indica que puede llevar **7 días o más**.

Lo que **sí** está en tu mano es no provocar retrasos:

- **Completa «Contenido de la aplicación» entera antes de enviar.** Si queda
  una sección a medias, la versión se queda esperando sin que nadie la mire.
- **Que las declaraciones coincidan con la realidad.** Si dices que no hay
  anuncios y los hay, o no declaras el ID de publicidad, es rechazo casi
  seguro.
- **Verifica tu identidad de desarrollador cuanto antes.** Es un trámite
  paralelo que bloquea la publicación aunque la revisión vaya bien.
- **Revisa el correo de la cuenta a diario.** Si Google pide una aclaración y
  tardas tres días en contestar, son tres días perdidos.
- **Nada de «Tetris» en los textos.** Una reclamación de marca es el peor
  escenario: retirada y aviso en la cuenta.

Si te rechazan, el correo dice exactamente qué política se incumplió. Mándamelo
y lo corregimos.
