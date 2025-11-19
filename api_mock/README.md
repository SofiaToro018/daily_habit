# API Mock - Habit Tracker

API Mock usando json-server para el proyecto Habit Tracker.

## 📋 Requisitos

- Node.js (v14 o superior)
- npm

## 🚀 Instalación

```bash
cd api_mock
npm install
```

## ▶️ Ejecutar el servidor

### Opción 1: Acceso local (solo desde tu computadora)
```bash
npm run start:local
```

La API estará disponible en: `http://localhost:3000`

### Opción 2: Acceso desde emulador/dispositivo (recomendado para Flutter)
```bash
npm start
```

La API estará disponible en:
- Desde tu PC: `http://localhost:3000`
- Desde emulador Android: `http://10.0.2.2:3000`
- Desde dispositivo físico: `http://TU_IP_LOCAL:3000` (ej: `http://192.168.1.100:3000`)

### Encontrar tu IP local:

**Windows:**
```powershell
ipconfig
```
Busca "Dirección IPv4" en tu adaptador de red WiFi/Ethernet.

**Mac/Linux:**
```bash
ifconfig
```

## 📚 Endpoints disponibles

### GET /habits
Obtiene todos los hábitos
```
GET http://localhost:3000/habits
```

### GET /habits/:id
Obtiene un hábito específico
```
GET http://localhost:3000/habits/1
```

### POST /habits
Crea un nuevo hábito
```
POST http://localhost:3000/habits
Content-Type: application/json

{
  "id": "4",
  "title": "Beber agua",
  "description": "2 litros al día",
  "completed": false,
  "updatedAt": "2025-11-18T10:00:00.000Z",
  "deleted": false,
  "lastCompletedAt": null,
  "streak": 0
}
```

### PUT /habits/:id
Actualiza un hábito existente
```
PUT http://localhost:3000/habits/1
Content-Type: application/json

{
  "id": "1",
  "title": "Hacer ejercicio",
  "description": "30 minutos de cardio",
  "completed": true,
  "updatedAt": "2025-11-18T10:00:00.000Z",
  "deleted": false,
  "lastCompletedAt": "2025-11-18T10:00:00.000Z",
  "streak": 1
}
```

### DELETE /habits/:id
Elimina un hábito
```
DELETE http://localhost:3000/habits/1
```

## 🔧 Configuración en Flutter

Edita el archivo `lib/data/remote/api_config.dart`:

```dart
class ApiConfig {
  // Para emulador Android
  static const String baseUrl = 'http://10.0.2.2:3000';
  
  // Para dispositivo físico (reemplaza con tu IP)
  // static const String baseUrl = 'http://192.168.1.100:3000';
  
  // Para iOS Simulator
  // static const String baseUrl = 'http://localhost:3000';
}
```

## 📝 Notas

- Los datos se guardan automáticamente en `db.json`
- El servidor se reinicia automáticamente al detectar cambios en `db.json`
- json-server soporta Idempotency-Key headers (útil para evitar duplicados)

## 🐛 Troubleshooting

### Error: "Cannot connect to API"
1. Verifica que el servidor json-server esté corriendo
2. Verifica que la URL en `api_config.dart` sea correcta
3. Verifica que no haya firewall bloqueando el puerto 3000

### Desde dispositivo Android físico no conecta
1. Asegúrate de que el dispositivo y la PC estén en la misma red WiFi
2. Usa tu IP local (no localhost)
3. Verifica que el firewall de Windows permita conexiones entrantes en el puerto 3000
