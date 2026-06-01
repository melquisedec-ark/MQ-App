# 🎨 Actualización de Directiva de Diseño: Paleta Corporativa (Negro, Dorado, Blanco)

## 📌 Contexto
Se aprueba el documento `PropuestaInterfaz.md` en su totalidad respecto a la estructura y experiencia de usuario (UX). Sin embargo, se requiere una **modificación estricta en la dirección de Arte (UI)** para alinear la aplicación con la identidad corporativa ejecutiva de MQ DevTeam.

## 🛠️ Modificación a la Propuesta 6 (Temas y Tipografía)

No se utilizará un `colorSchemeSeed` genérico de Material 3 que genere paletas automáticas impredecibles. Se debe definir un `ColorScheme` totalmente personalizado y manual en `app_theme.dart` respetando la siguiente paleta:

1.  **Fondo Principal (Background / Surface):** * *Modo Oscuro (Principal):* Negro absoluto (`#000000`) o un Gris Carbón extremadamente oscuro (`#111111`) para pantallas OLED y reducción de fatiga visual.
    * *Modo Claro:* Blanco puro (`#FFFFFF`) o un Blanco Roto casi imperceptible (`#FAFAFA`).
2.  **Color Primario (Acentos, Botones, Iconos Activos, Acordes):**
    * Dorado corporativo MQ (`#CCA43B` o el hexadecimal exacto de la marca). Este color debe usarse estratégicamente para guiar el ojo del usuario (ej. FAB, switches, la letra de los acordes musicales).
3.  **Color de Texto (OnSurface / OnBackground):**
    * Blanco puro sobre fondos negros (alto contraste).
    * Negro carbón sobre fondos blancos.

### 📋 Requerimientos de Implementación en UI:
* **Tarjetas y Sheets:** Los contenedores como el `HymnCard` o el `DraggableScrollableSheet` del Brush Sheet no deben tener colores sólidos fuertes de fondo. Deben usar la técnica de *Glassmorphism* leve (como se aprobó previamente para los acordes) o bordes sutiles grises/dorados sobre el fondo negro para separarlos visualmente.
* **Botones Inactivos:** Utilizar escalas de grises oscuros para elementos inactivos o secundarios, nunca colores fuera de la paleta.