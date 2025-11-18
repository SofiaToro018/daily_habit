# 🎯 Daily Habit Tracker

Una aplicación Flutter moderna para rastrear hábitos diarios con arquitectura limpia, modo offline-first y sincronización automática.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![License](https://img.shields.io/badge/license-MIT-green)

## 📱 Características

- ✅ **Crear, editar y eliminar hábitos** con descripción
- 🎯 **Marcar hábitos como completados/pendientes**
- 🔥 **Sistema de rachas** (streak tracking) para motivación
- 📊 **Filtros múltiples**: Todos, Pendientes, Completados, Con rachas
- 💾 **Persistencia local con SQLite** - funciona sin internet
- 🌐 **Modo Offline-First** con sincronización automática
- ⚡ **Sincronización inteligente** con backoff exponencial
- 🎨 **Diseño moderno y animaciones fluidas**
- 🏗️ **Arquitectura limpia** y separación de capas
- 📡 **Manejo robusto de errores** (timeouts, 4xx/5xx)

## 🏗️ Arquitectura

El proyecto sigue los principios de **Clean Architecture** con las siguientes capas:

```
lib/
├── core/
│   ├── models/          # Modelos de datos (Habit, QueueOperation)
│   └── theme/           # Tema y estilos de la app
├── data/
│   ├── local/           # Capa de datos local (SQLite)
│   │   ├── database_helper.dart
│   │   ├── habit_dao.dart
│   │   └── queue_dao.dart
│   ├── remote/          # Capa de datos remota (API)
│   │   ├── api_client.dart
│   │   ├── api_config.dart
│   │   └── habit_api_service.dart
│   └── repositories/    # Repositorios (lógica offline-first)
│       └── habit_repository.dart
├── providers/           # Gestión de estado (Riverpod)
│   └── habit_providers.dart
├── services/            # Servicios de negocio
│   └── sync_service.dart
└── presentation/        # UI
    ├── screens/
    │   └── home_screen.dart
    └── widgets/
        └── habit_card.dart
```

## 🚀 Instalación y Configuración

### Prerrequisitos

- Flutter 3.x o superior
- Dart 3.x o superior
- Node.js (para json-server)

### Paso 1: Clonar el repositorio

```bash
git clone https://github.com/SofiaToro018/daily_habit.git
cd daily_habit
```

### Paso 2: Instalar dependencias de Flutter

```bash
flutter pub get
```

### Paso 3: Configurar y ejecutar la API Mock

```bash
cd api_mock
npm install
npm start
```

La API estará disponible en `http://localhost:3000`

### Paso 4: Configurar la URL de la API

Edita `lib/data/remote/api_config.dart`:

```dart
class ApiConfig {
  // Para emulador Android
  static const String baseUrl = 'http://10.0.2.2:3000';
  
  // Para dispositivo físico (reemplaza con tu IP local)
  // static const String baseUrl = 'http://192.168.1.100:3000';
  
  // Para iOS Simulator o desarrollo web
  // static const String baseUrl = 'http://localhost:3000';
}
```

### Paso 5: Ejecutar la aplicación

```bash
flutter run
```

## 📦 Dependencias Principales

```yaml
dependencies:
  flutter_riverpod: ^2.5.1      # Gestión de estado
  sqflite: ^2.3.3+1              # Base de datos SQLite
  http: ^1.2.1                   # Cliente HTTP
  connectivity_plus: ^6.0.5      # Detección de conectividad
  uuid: ^4.4.0                   # Generación de IDs únicos
  google_fonts: ^6.2.1           # Tipografías modernas
  flutter_animate: ^4.5.0        # Animaciones
  intl: ^0.19.0                  # Internacionalización
```

## 🎯 Características Técnicas Destacadas

### 1. Estrategia Offline-First

La aplicación prioriza la experiencia del usuario funcionando completamente offline:

- **Lecturas**: Datos locales se muestran inmediatamente
- **Escrituras**: Se guardan localmente y se encolan para sincronización
- **Sincronización**: Automática cuando se detecta conectividad

### 2. Cola de Sincronización

Sistema robusto de cola con:

- ✅ Reintentos automáticos con backoff exponencial
- ✅ Manejo de errores con registro detallado
- ✅ Límite de intentos para evitar loops infinitos
- ✅ Idempotency-Key para evitar duplicaciones

### 3. Resolución de Conflictos

Estrategia **Last-Write-Wins (LWW)**:
- Se compara el campo `updatedAt`
- El dato más reciente prevalece
- Sincronización bidireccional (local ↔️ servidor)

### 4. Gestión de Estado con Riverpod

- Providers para acceso a repositorios y servicios
- StateNotifiers para estado mutable
- FutureProviders para datos asíncronos
- Invalidación automática para refrescar UI

## 📚 API Mock (json-server)

### Endpoints Disponibles

| Método | Endpoint      | Descripción                |
|--------|---------------|----------------------------|
| GET    | /habits       | Obtener todos los hábitos  |
| GET    | /habits/:id   | Obtener un hábito          |
| POST   | /habits       | Crear un hábito            |
| PUT    | /habits/:id   | Actualizar un hábito       |
| DELETE | /habits/:id   | Eliminar un hábito         |

### Formato de Datos

```json
{
  "id": "uuid",
  "title": "Título del hábito",
  "description": "Descripción opcional",
  "completed": false,
  "updatedAt": "2025-11-18T08:00:00.000Z",
  "deleted": false,
  "lastCompletedAt": null,
  "streak": 0
}
```

## 🎨 Diseño y UX

- **Material Design 3** con paleta de colores moderna
- **Animaciones fluidas** con flutter_animate
- **Tipografía Google Fonts** (Inter)
- **Diseño responsive** y adaptativo
- **Indicadores visuales** de estado de sincronización
- **Sistema de rachas** con iconos de fuego 🔥

## 🔐 Persistencia Local

### Esquema de Base de Datos

#### Tabla `habits`
```sql
CREATE TABLE habits (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  completed INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0,
  last_completed_at TEXT,
  streak INTEGER NOT NULL DEFAULT 0
);
```

#### Tabla `queue_operations`
```sql
CREATE TABLE queue_operations (
  id TEXT PRIMARY KEY,
  entity TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  op TEXT NOT NULL,
  payload TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT
);
```

## 🧪 Testing

```bash
# Ejecutar tests unitarios
flutter test

# Ejecutar tests con cobertura
flutter test --coverage
```

## 📖 Documentación del Código

Cada clase y método está documentado siguiendo las convenciones de Dart:

```dart
/// Descripción breve de la clase
/// 
/// Descripción detallada del propósito y funcionamiento.
class Example {
  /// Descripción del método
  /// 
  /// [param1] - Descripción del parámetro
  /// Returns: Descripción del valor de retorno
  void method(String param1) {
    // Implementación
  }
}
```

## 🚀 Próximas Mejoras

- [ ] Notificaciones push para recordatorios
- [ ] Gráficos de progreso semanal/mensual
- [ ] Categorías de hábitos
- [ ] Modo oscuro
- [ ] Exportar/Importar datos
- [ ] Autenticación de usuarios
- [ ] Sincronización en la nube

## 👨‍💻 Desarrollo

### Comandos Útiles

```bash
# Analizar código
flutter analyze

# Formatear código
dart format lib/

# Limpiar build
flutter clean && flutter pub get

# Generar build release
flutter build apk --release
```

## 🐛 Troubleshooting

### La app no conecta con la API

1. Verifica que json-server esté corriendo
2. Verifica la URL en `api_config.dart`
3. Revisa el firewall (puerto 3000)

### Errores de sincronización

1. Revisa los logs en la consola
2. Verifica la conectividad de red
3. Revisa la tabla `queue_operations` en SQLite

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.

## 👥 Autores

- **Laura Sofia Toro** - [SofiaToro018](https://github.com/SofiaToro018)

## 🙏 Agradecimientos

- Flutter team por el framework increíble
- Riverpod por la gestión de estado elegante
- json-server por facilitar el mock de API

---

**Desarrollado con ❤️ usando Flutter**

