/// Configuración de la API
class ApiConfig {
  // Cambiar esta URL cuando uses json-server
  // Ejemplo: 'http://localhost:3000' o 'http://10.0.2.2:3000' para emulador Android
  static const String baseUrl = 'http://localhost:3000';

  static const Duration timeout = Duration(seconds: 10);

  // Endpoints
  static const String habitsEndpoint = '/habits';

  static String habitByIdEndpoint(String id) => '/habits/$id';
}
