/// Catálogo local de departamentos y ciudades de Colombia (spec 004, RF-02).
///
/// ADR-002: el dataset va **embebido** para no depender de la red. Cubre los 32
/// departamentos y Bogotá D.C. con sus principales municipios. Si se necesita el
/// listado completo del DANE, se reemplaza este mapa sin tocar el resto.
library;

/// Departamentos y sus principales ciudades/municipios.
const Map<String, List<String>> departamentosCiudades = <String, List<String>>{
  'Amazonas': <String>['Leticia', 'Puerto Nariño'],
  'Antioquia': <String>[
    'Medellín',
    'Bello',
    'Itagüí',
    'Envigado',
    'Sabaneta',
    'La Estrella',
    'Rionegro',
    'Marinilla',
    'Apartadó',
    'Turbo',
    'Caucasia',
  ],
  'Arauca': <String>['Arauca', 'Saravena', 'Tame', 'Arauquita'],
  'Atlántico': <String>[
    'Barranquilla',
    'Soledad',
    'Malambo',
    'Sabanalarga',
    'Puerto Colombia',
    'Galapa',
  ],
  'Bolívar': <String>[
    'Cartagena',
    'Magangué',
    'Turbaco',
    'Arjona',
    'El Carmen de Bolívar',
  ],
  'Boyacá': <String>[
    'Tunja',
    'Sogamoso',
    'Duitama',
    'Chiquinquirá',
    'Puerto Boyacá',
    'Paipa',
  ],
  'Caldas': <String>[
    'Manizales',
    'Villamaría',
    'La Dorada',
    'Chinchiná',
    'Riosucio',
  ],
  'Caquetá': <String>['Florencia', 'San Vicente del Caguán', 'Puerto Rico'],
  'Casanare': <String>['Yopal', 'Aguazul', 'Villanueva', 'Paz de Ariporo'],
  'Cauca': <String>[
    'Popayán',
    'Santander de Quilichao',
    'Puerto Tejada',
    'Patía',
    'Guapi',
  ],
  'Cesar': <String>['Valledupar', 'Aguachica', 'Codazzi', 'Bosconia', 'La Jagua de Ibirico'],
  'Chocó': <String>['Quibdó', 'Istmina', 'Riosucio', 'Condoto'],
  'Córdoba': <String>[
    'Montería',
    'Cereté',
    'Sahagún',
    'Lorica',
    'Planeta Rica',
    'Montelíbano',
  ],
  'Cundinamarca': <String>[
    'Soacha',
    'Zipaquirá',
    'Fusagasugá',
    'Facatativá',
    'Chía',
    'Girardot',
    'Mosquera',
    'Madrid',
    'Funza',
    'Cajicá',
    'La Calera',
  ],
  'Guainía': <String>['Inírida'],
  'Guaviare': <String>['San José del Guaviare', 'Calamar'],
  'Huila': <String>['Neiva', 'Pitalito', 'Garzón', 'La Plata', 'Campoalegre'],
  'La Guajira': <String>['Riohacha', 'Maicao', 'Uribia', 'Fonseca', 'Villanueva'],
  'Magdalena': <String>['Santa Marta', 'Ciénaga', 'Fundación', 'El Banco', 'Aracataca'],
  'Meta': <String>['Villavicencio', 'Acacías', 'Granada', 'Puerto López', 'Cumaral'],
  'Nariño': <String>['Pasto', 'Ipiales', 'Tumaco', 'Túquerres', 'La Unión'],
  'Norte de Santander': <String>[
    'Cúcuta',
    'Villa del Rosario',
    'Los Patios',
    'Ocaña',
    'Pamplona',
  ],
  'Putumayo': <String>['Mocoa', 'Puerto Asís', 'Orito', 'Valle del Guamuez'],
  'Quindío': <String>['Armenia', 'Calarcá', 'Montenegro', 'La Tebaida', 'Quimbaya'],
  'Risaralda': <String>[
    'Pereira',
    'Dosquebradas',
    'Santa Rosa de Cabal',
    'La Virginia',
    'Marsella',
  ],
  'San Andrés y Providencia': <String>['San Andrés', 'Providencia'],
  'Santander': <String>[
    'Bucaramanga',
    'Floridablanca',
    'Girón',
    'Piedecuesta',
    'Barrancabermeja',
    'San Gil',
    'Socorro',
  ],
  'Sucre': <String>['Sincelejo', 'Corozal', 'Sampués', 'San Marcos', 'Tolú'],
  'Tolima': <String>['Ibagué', 'Espinal', 'Melgar', 'Honda', 'Líbano'],
  'Valle del Cauca': <String>[
    'Cali',
    'Buenaventura',
    'Palmira',
    'Tuluá',
    'Cartago',
    'Buga',
    'Yumbo',
    'Jamundí',
    'Florida',
  ],
  'Vaupés': <String>['Mitú'],
  'Vichada': <String>['Puerto Carreño', 'La Primavera'],
  'Bogotá D.C.': <String>['Bogotá'],
};

/// Departamentos ordenados alfabéticamente.
List<String> get departamentos {
  final lista = departamentosCiudades.keys.toList();
  lista.sort();
  return lista;
}

/// Ciudades de un departamento (lista vacía si no existe). RN-04.
List<String> ciudadesDe(String departamento) =>
    departamentosCiudades[departamento] ?? const <String>[];
