# Aplicativo de Ventas

Aplicativo multiplataforma de gestion de ventas (Android, iOS y Web) desarrollado en Flutter + Firebase.

## Descripcion

Sistema de ventas para distribuidores, venta al detal (minorista) y al por mayor (mayorista), con arquitectura **multi-tenant** (una sola aplicacion para multiples empresas).

### Modulos principales
- Catalogo de productos (con fotos, descripciones, medidas y precios)
- Carrito y pedidos (clientes invitados y registrados)
- Clientes, Ventas, Ventas a credito y cobros
- Proveedores y compras con anexos legales (facturas escaneadas, PDFs)
- Inventario, Caja y trazabilidad del dinero
- Envios, entregas locales y recogida en local
- Ubicacion GPS (Google Maps)
- Reportes, Auditoria y Logs de errores
- Parametros generales, temas y paletas de colores
- Arquitectura multi-tenant (multiples empresas)
- Licencias y planes por empresa (mensual / anual)

## Documentacion

La documentacion del proyecto se encuentra en la carpeta [`Documentacion`](./Documentacion):

- `aplicativo ventas.docx` — Documento de levantamiento de requerimientos

## Tecnologia

- **Frontend:** Flutter (Android, iOS, Web)
- **Backend / Base de datos:** Firebase Firestore
- **Autenticacion:** Firebase Authentication
- **Archivos:** Firebase Storage
- **Logica de servidor:** Cloud Functions

## Repositorio

- GitHub: `git@github.com:Esteban-barrero/ventas.git`
