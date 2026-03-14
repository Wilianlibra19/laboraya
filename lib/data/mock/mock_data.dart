import 'package:uuid/uuid.dart';
import '../../core/models/user_model.dart';
import '../../core/models/job_model.dart';

class MockData {
  static const uuid = Uuid();

  static List<UserModel> getMockUsers() {
    return [
      UserModel(
        id: 'user1',
        name: 'Carlos Mendoza',
        phone: '987654321',
        email: 'carlos@example.com',
        district: 'San Isidro',
        rating: 4.8,
        completedJobs: 45,
        skills: ['Construcción', 'Albañilería', 'Pintura'],
        availability: 'Lunes a Sábado',
        description: 'Maestro constructor con 10 años de experiencia',
        documents: [],
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
      UserModel(
        id: 'user2',
        name: 'María Torres',
        phone: '987654322',
        email: 'maria@example.com',
        district: 'Miraflores',
        rating: 4.9,
        completedJobs: 67,
        skills: ['Limpieza', 'Organización'],
        availability: 'Todos los días',
        description: 'Especialista en limpieza profunda',
        documents: [],
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
      ),
      UserModel(
        id: 'user3',
        name: 'José Ramírez',
        phone: '987654323',
        email: 'jose@example.com',
        district: 'Surco',
        rating: 4.7,
        completedJobs: 32,
        skills: ['Mudanza', 'Carga', 'Transporte'],
        availability: 'Fines de semana',
        description: 'Servicio de mudanzas rápido y seguro',
        documents: [],
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
    ];
  }

  static List<JobModel> getMockJobs() {
    final now = DateTime.now();
    return [
      JobModel(
        id: uuid.v4(),
        title: 'Subir ladrillos a segundo piso',
        description:
            'Necesito ayuda para subir aproximadamente 500 ladrillos al segundo piso de mi casa en construcción.',
        category: 'Construcción',
        payment: 80,
        paymentType: 'Por día',
        workersNeeded: 2,
        duration: '4 horas',
        latitude: -12.0464,
        longitude: -77.0428,
        address: 'Av. Arequipa 1234, Miraflores',
        createdBy: 'user1',
        status: 'available',
        isUrgent: false,
        images: [],
        createdAt: now.subtract(const Duration(hours: 2)),
        scheduledDate: now.add(const Duration(days: 1)),
      ),
      JobModel(
        id: uuid.v4(),
        title: 'Ayuda para mudanza pequeña',
        description:
            'Mudanza de departamento pequeño, solo muebles básicos. Tengo el camión, necesito ayuda para cargar y descargar.',
        category: 'Mudanza',
        payment: 100,
        paymentType: 'Por trabajo',
        workersNeeded: 2,
        duration: '3 horas',
        latitude: -12.0897,
        longitude: -77.0501,
        address: 'Calle Los Pinos 456, San Isidro',
        createdBy: 'user2',
        status: 'available',
        isUrgent: true,
        images: [],
        createdAt: now.subtract(const Duration(hours: 5)),
        scheduledDate: now.add(const Duration(hours: 6)),
      ),
      JobModel(
        id: uuid.v4(),
        title: 'Limpieza de local comercial',
        description:
            'Limpieza profunda de local comercial de 80m2. Incluye pisos, ventanas y baños.',
        category: 'Limpieza',
        payment: 150,
        paymentType: 'Por trabajo',
        workersNeeded: 1,
        duration: '5 horas',
        latitude: -12.1191,
        longitude: -77.0350,
        address: 'Av. Larco 789, Miraflores',
        createdBy: 'user3',
        status: 'available',
        isUrgent: false,
        images: [],
        createdAt: now.subtract(const Duration(hours: 8)),
        scheduledDate: now.add(const Duration(days: 2)),
      ),
      JobModel(
        id: uuid.v4(),
        title: 'Descarga de mercadería',
        description:
            'Necesito ayuda para descargar camión con mercadería (cajas de 20kg aprox). Trabajo en almacén.',
        category: 'Carga',
        payment: 60,
        paymentType: 'Por día',
        workersNeeded: 3,
        duration: '2 horas',
        latitude: -12.0700,
        longitude: -77.0500,
        address: 'Av. Javier Prado 2345, San Isidro',
        createdBy: 'user1',
        status: 'available',
        isUrgent: true,
        images: [],
        createdAt: now.subtract(const Duration(minutes: 45)),
        scheduledDate: now.add(const Duration(hours: 3)),
      ),
      JobModel(
        id: uuid.v4(),
        title: 'Jardinería por medio día',
        description:
            'Mantenimiento de jardín: cortar césped, podar arbustos y limpiar área verde de 100m2.',
        category: 'Jardinería',
        payment: 120,
        paymentType: 'Por trabajo',
        workersNeeded: 1,
        duration: '4 horas',
        latitude: -12.1100,
        longitude: -77.0450,
        address: 'Calle Las Flores 567, Surco',
        createdBy: 'user2',
        status: 'available',
        isUrgent: false,
        images: [],
        createdAt: now.subtract(const Duration(hours: 12)),
        scheduledDate: now.add(const Duration(days: 3)),
      ),
      JobModel(
        id: uuid.v4(),
        title: 'Ayuda en reparto',
        description:
            'Necesito ayudante para reparto de productos en moto. Conocimiento de Lima es importante.',
        category: 'Reparto',
        payment: 80,
        paymentType: 'Por día',
        workersNeeded: 1,
        duration: '8 horas',
        latitude: -12.0600,
        longitude: -77.0380,
        address: 'Av. Benavides 890, Miraflores',
        createdBy: 'user3',
        status: 'available',
        isUrgent: false,
        images: [],
        createdAt: now.subtract(const Duration(hours: 24)),
        scheduledDate: now.add(const Duration(days: 1)),
      ),
    ];
  }

  static List<String> getCategories() {
    return [
      // Construcción y Mantenimiento
      'Limpieza',
      'Construcción',
      'Plomería',
      'Electricidad',
      'Carpintería',
      'Pintura',
      'Gasfitería',
      'Cerrajería',
      'Albañilería',
      'Soldadura',
      'Mecánica',
      'Reparaciones',
      'Instalaciones',
      'Mantenimiento',
      
      // Transporte y Logística
      'Mudanza',
      'Carga y Descarga',
      'Reparto / Delivery',
      'Chofer',
      'Mensajería',
      
      // Servicios del Hogar
      'Limpieza Profunda',
      'Fumigación',
      'Jardinería',
      'Lavandería',
      'Planchado',
      'Niñera / Cuidado',
      'Cuidado de Adultos Mayores',
      'Cuidado de Mascotas',
      
      // Gastronomía y Eventos
      'Cocinero',
      'Mesero / Mozo',
      'Bartender',
      'Chef a Domicilio',
      'Repostería',
      'Catering',
      
      // Belleza y Bienestar
      'Peluquería',
      'Barbería',
      'Manicure / Pedicure',
      'Masajes',
      'Maquillaje',
      'Estética',
      
      // Servicios Personales
      'Costura',
      'Sastrería',
      'Zapatería',
      'Seguridad',
      'Ayudante General',
      
      // Tecnología e Informática
      'Programación',
      'Desarrollo Web',
      'Desarrollo de Apps',
      'Soporte Técnico',
      'Reparación de Computadoras',
      'Reparación de Celulares',
      'Instalación de Software',
      'Redes e Internet',
      'Base de Datos',
      'Ciberseguridad',
      
      // Diseño y Multimedia
      'Diseño Gráfico',
      'Diseño Web',
      'Diseño de Interiores',
      'Arquitectura',
      'Fotografía',
      'Video',
      'Edición de Video',
      'Animación',
      'Ilustración',
      'Modelado 3D',
      
      // Educación
      'Clases Particulares',
      'Tutoría Escolar',
      'Clases de Inglés',
      'Clases de Matemáticas',
      'Clases de Música',
      'Clases de Baile',
      'Clases de Deportes',
      'Capacitación',
      
      // Ingenierías
      'Ingeniería Civil',
      'Ingeniería Industrial',
      'Ingeniería de Sistemas',
      'Ingeniería Eléctrica',
      'Ingeniería Electrónica',
      'Ingeniería Mecánica',
      'Ingeniería Química',
      'Ingeniería Ambiental',
      'Ingeniería de Minas',
      'Ingeniería Agrónoma',
      'Ingeniería de Telecomunicaciones',
      
      // Profesionales
      'Abogado',
      'Contador',
      'Administrador',
      'Economista',
      'Arquitecto',
      'Médico',
      'Enfermero',
      'Psicólogo',
      'Nutricionista',
      'Veterinario',
      'Odontólogo',
      'Fisioterapeuta',
      
      // Marketing y Comunicación
      'Marketing Digital',
      'Community Manager',
      'Publicidad',
      'Relaciones Públicas',
      'Copywriting',
      'SEO / SEM',
      'Social Media',
      
      // Negocios y Finanzas
      'Contabilidad',
      'Auditoría',
      'Finanzas',
      'Asesoría Empresarial',
      'Recursos Humanos',
      'Ventas',
      
      // Legal
      'Asesoría Legal',
      'Trámites Legales',
      'Notaría',
      
      // Traducción e Idiomas
      'Traducción',
      'Interpretación',
      'Transcripción',
      
      // Otros
      'Otros',
    ];
  }
}
