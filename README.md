# Calculadora de Bencina (SwiftUI + MapKit)

Proyecto iOS en SwiftUI para calcular consumo y costo de bencina por tramos usando rutas reales de MapKit (`MKDirections`) cuando están disponibles.

## Funcionalidades implementadas
- Mapa interactivo con toques para agregar paradas.
- Búsqueda de lugares por nombre/dirección.
- Marcadores por parada y trazado de ruta entre puntos en orden.
- Cálculo por tramo: distancia, litros y costo.
- Resumen total: distancia, litros, gasto y duración estimada.
- Punto inicial con ubicación actual.
- Eliminar y reordenar paradas (acciones rápidas).
- Selector visual de bencina 93/95/97.
- Limpieza total de ruta.
- Formateo de moneda en CLP.

## Fórmulas
- `litros = distancia_km / rendimiento_km_por_litro`
- `costo = litros * precio_litro`

## Requisitos
- Xcode 16+
- iOS 17+

## Cómo abrir
1. Abrir `CalculadoraDeBencina.xcodeproj`.
2. Seleccionar un simulador de iPhone.
3. Ejecutar.

> Nota: si `MKDirections` no logra calcular una ruta (por red/servicio), el tramo usa distancia en línea recta como respaldo.
