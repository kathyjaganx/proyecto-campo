# Modelo de datos

## activos
- id (PK)
- codigo (único)
- tipo_activo_id (FK → tipos_activo.id)
- cliente_id (FK → clientes.id)
- estado