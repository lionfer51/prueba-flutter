# Maps Notification Bridge (Flutter)

Aplicación Flutter enfocada en Android para escuchar notificaciones de Google Maps (`com.google.android.apps.maps`) usando `NotificationListenerService` y reenviar una notificación local con el contenido para escenarios de navegación.

## Flujo

1. La app solicita permiso de notificaciones (`POST_NOTIFICATIONS`).
2. El usuario habilita acceso de *Notification Listener* en ajustes del sistema.
3. `MapsNotificationListenerService` recibe notificaciones publicadas por el sistema.
4. Solo si provienen de Google Maps, se envía el payload por `EventChannel` a Flutter.
5. Flutter publica una notificación local duplicada con el texto recibido.
6. `KeepAliveForegroundService` corre en primer plano para mejorar supervivencia en segundo plano.

## Importante

- Esto solo funciona en **Android** (iOS no permite esta capacidad).
- Algunos fabricantes aplican optimizaciones de batería agresivas; el usuario debe excluir la app de ahorro de energía para mayor estabilidad.
- La app no evade restricciones de sistema: depende de permisos y políticas de Android.

## Configuración adicional recomendada

- Desactivar optimización de batería para la app.
- Permitir auto-inicio en fabricantes que lo requieran (Xiaomi/OPPO/Vivo, etc.).
- Mantener servicio foreground activo.
