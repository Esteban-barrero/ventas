import 'caja.dart';

/// Cálculos de caja (spec 009). Se aíslan para poder probarlos.

/// Saldo resultante al aplicar un movimiento (RN-04):
/// los ingresos suman; egresos, retiros y gastos restan.
double saldoConMovimiento(double saldo, TipoMovimientoCaja tipo, double monto) =>
    saldo + (tipo.suma ? monto : -monto);

/// Diferencia del arqueo (RN-05): `contado − esperado`
/// (`> 0` sobrante, `= 0` cuadre, `< 0` faltante).
double calcularDiferenciaArqueo(double totalContado, double totalEsperado) =>
    totalContado - totalEsperado;
