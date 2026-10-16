/// Lista estándar de categorías del catálogo (spec 003).
///
/// Se **siembra** automáticamente la primera vez que una empresa usa el
/// catálogo, para que el formulario de producto tenga opciones desde el inicio.
/// Cada empresa puede luego editarlas (agregar, quitar, activar) a su gusto.
library;

/// Categorías que recibe toda empresa nueva (y las existentes sin categorías).
const List<String> categoriasEstandar = <String>[
  'Ropa',
  'Calzado',
  'Accesorios',
  'Alimentos',
  'Bebidas',
  'Aseo',
  'Hogar',
  'Belleza y cuidado personal',
  'Tecnología',
  'Juguetes',
  'Papelería',
  'Deportes',
  'Herramientas',
  'Mascotas',
  'Otros',
];
