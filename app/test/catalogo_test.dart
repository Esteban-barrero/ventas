import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auth/domain/usuario.dart';
import 'package:ventas_app/features/catalogo/data/categorias_repository.dart';
import 'package:ventas_app/features/catalogo/data/productos_repository.dart';
import 'package:ventas_app/features/catalogo/domain/categoria.dart';
import 'package:ventas_app/features/catalogo/domain/precio.dart';
import 'package:ventas_app/features/catalogo/domain/producto.dart';
import 'package:ventas_app/features/catalogo/presentation/catalogo_screen.dart';
import 'package:ventas_app/features/empresas/data/empresas_repository.dart';
import 'package:ventas_app/features/empresas/domain/empresa.dart';
import 'package:ventas_app/features/empresas/domain/parametros_empresa.dart';

/// Repositorio de productos en memoria para las pruebas de widget.
class _FakeProductos extends ProductosRepository {
  _FakeProductos(this.items);

  final List<Producto> items;

  @override
  Stream<List<Producto>> escuchar(String empresaId) => Stream.value(items);
}

class _FakeCategorias extends CategoriasRepository {
  @override
  Stream<List<Categoria>> escuchar(String empresaId) =>
      Stream.value(const <Categoria>[]);
}

class _FakeEmpresas extends EmpresasRepository {
  @override
  Future<Empresa?> obtener(String empresaId) async =>
      const Empresa(id: 'e', nombre: 'Empresa', nit: '1');
}

void main() {
  group('calcularPrecio (RN-03)', () {
    test('aplica el margen sobre el costo', () {
      expect(calcularPrecio(20000, 50), 30000);
    });

    test('un margen negativo se trata como 0', () {
      expect(calcularPrecio(20000, -10), 20000);
    });
  });

  group('margen y precio (RN-01, RN-02)', () {
    const empresa = ParametrosEmpresa(margenContado: 30, margenCredito: 40);

    test('hereda el margen general si el producto no define', () {
      const p = Producto(
        id: 'p',
        empresaId: 'e',
        codigo: 'C',
        nombre: 'N',
        costo: 1000,
      );
      expect(p.margenEfectivo(TipoPrecio.contado, empresa), 30);
      expect(p.margenEfectivo(TipoPrecio.credito, empresa), 40);
      expect(p.precio(TipoPrecio.contado, empresa), 1300);
      expect(p.precio(TipoPrecio.credito, empresa), 1400);
    });

    test('usa el margen propio contado/crédito si lo define', () {
      const p = Producto(
        id: 'p',
        empresaId: 'e',
        codigo: 'C',
        nombre: 'N',
        costo: 1000,
        margenContado: 50,
        margenCredito: 65,
      );
      expect(p.precio(TipoPrecio.contado, empresa), 1500);
      expect(p.precio(TipoPrecio.credito, empresa), 1650);
    });
  });

  group('costo de envío (RN-04)', () {
    const empresa = ParametrosEmpresa(costoEnvio: 18000);

    test('hereda el general', () {
      const p = Producto(id: 'p', empresaId: 'e', codigo: 'C', nombre: 'N');
      expect(p.costoEnvioEfectivo(empresa), 18000);
    });

    test('el individual tiene prioridad', () {
      const p = Producto(
        id: 'p',
        empresaId: 'e',
        codigo: 'C',
        nombre: 'N',
        costoEnvio: 5000,
      );
      expect(p.costoEnvioEfectivo(empresa), 5000);
    });
  });

  group('alerta de stock (RN-07)', () {
    test('es "stock bajo" cuando llega al mínimo', () {
      const p = Producto(
        id: 'p',
        empresaId: 'e',
        codigo: 'C',
        nombre: 'N',
        stock: 5,
        stockMinimo: 5,
      );
      expect(p.stockBajo, isTrue);
    });
  });

  group('filtros del catálogo (RF-09)', () {
    const productos = <Producto>[
      Producto(
        id: '1',
        empresaId: 'e',
        codigo: 'A-1',
        nombre: 'Camiseta Polo',
        categoriaId: 'rop',
      ),
      Producto(
        id: '2',
        empresaId: 'e',
        codigo: 'B-2',
        nombre: 'Gorra',
        categoriaId: 'acc',
        activo: false,
      ),
    ];

    test('filtra por categoría', () {
      final r = ProductosRepository.filtrar(productos, categoriaId: 'rop');
      expect(r.map((p) => p.id), <String>['1']);
    });

    test('busca por nombre o código', () {
      expect(
        ProductosRepository.filtrar(productos, busqueda: 'polo').map((p) => p.id),
        <String>['1'],
      );
      expect(
        ProductosRepository.filtrar(productos, busqueda: 'b-2').map((p) => p.id),
        <String>['2'],
      );
    });

    test('soloActivos excluye los inactivos', () {
      final r = ProductosRepository.filtrar(productos, soloActivos: true);
      expect(r.map((p) => p.id), <String>['1']);
    });
  });

  group('serialización del producto', () {
    test('guarda solo los márgenes definidos y los recupera', () {
      const p = Producto(
        id: 'p',
        empresaId: 'e',
        codigo: 'C',
        nombre: 'N',
        costo: 1000,
        margenContado: 50,
      );
      final map = p.toMap();
      expect(map['margenes'], <String, dynamic>{'contado': 50.0});

      final vuelta = Producto.fromMap('p', map);
      expect(vuelta.margenContado, 50);
      expect(vuelta.margenCredito, isNull);
      expect(vuelta.empresaId, 'e');
    });
  });

  testWidgets('el catálogo muestra las tarjetas de los productos',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u1',
      nombre: 'Admin',
      email: 'admin@ejemplo.com',
      empresaId: 'e',
      roles: <String>['administrador'],
    );
    final productos = _FakeProductos(const <Producto>[
      Producto(
        id: 'p1',
        empresaId: 'e',
        codigo: 'C1',
        nombre: 'Camiseta Polo',
        costo: 20000,
        stock: 10,
        stockMinimo: 2,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogoScreen(
          usuario: usuario,
          productosRepository: productos,
          categoriasRepository: _FakeCategorias(),
          empresasRepository: _FakeEmpresas(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Camiseta Polo'), findsOneWidget);
    expect(find.text('Nuevo producto'), findsOneWidget);
  });
}
