# Modelo de datos - Centro de Operaciones de Campo, Activos e Incidentes

## Seguridad y control de acceso

### usuarios
- id (PK)
- nombre
- correo (único)
- contrasena_hash
- activo (booleano)
- creado_en

### roles
- id (PK)
- nombre (único)

### permisos
- id (PK)
- codigo (único, por ejemplo: "ordenes.cerrar")

### roles_permisos
- rol_id (PK, FK → roles.id)
- permiso_id (PK, FK → permisos.id)

### usuarios_roles
- usuario_id (PK, FK → usuarios.id)
- rol_id (PK, FK → roles.id)

### tokens
- id (PK)
- proposito (ejemplo: "validar_activo", "aprobar_cierre")
- referencia_tipo (ejemplo: "activo", "orden")
- referencia_id
- hash_token (único; nunca se guarda el token en texto plano)
- expira_en
- estado (vigente, usado, revocado, vencido)
- creado_por (FK → usuarios.id)
- usado_en (nullable)

### auditoria
- id (PK)
- usuario_id (FK → usuarios.id, nullable)
- accion
- tabla
- registro_id
- datos_anteriores (JSON, nullable)
- datos_nuevos (JSON, nullable)
- ip
- creado_en

## Clientes y activos

### clientes
- id (PK)
- nombre
- direccion
- latitud
- longitud

### tipos_activo
- id (PK)
- nombre (ejemplo: poste, transformador, antena, medidor)

### activos
- id (PK)
- codigo (único, lo que se escanea con QR)
- tipo_activo_id (FK → tipos_activo.id)
- cliente_id (FK → clientes.id)
- ubicacion
- estado (operativo, en_falla, en_mantenimiento, fuera_de_servicio)

## Incidentes y órdenes de trabajo

### prioridades_sla
- id (PK)
- nivel (ejemplo: critica, alta, media, baja)
- tiempo_respuesta_horas
- tiempo_resolucion_horas

### incidentes
- id (PK)
- activo_id (FK → activos.id)
- descripcion
- reportado_por (FK → usuarios.id)
- fecha_reporte

### ordenes_trabajo
- id (PK)
- incidente_id (FK → incidentes.id)
- activo_id (FK → activos.id)
- prioridad_id (FK → prioridades_sla.id)
- estado (creada, asignada, aceptada, en_proceso, pendiente_cierre, cerrada, rechazada)
- diagnostico
- solucion
- fecha_creacion
- fecha_inicio
- fecha_cierre
- aprobado_por (FK → usuarios.id, nullable)

### historial_estados_orden
- id (PK)
- orden_id (FK → ordenes_trabajo.id)
- estado_anterior
- estado_nuevo
- usuario_id (FK → usuarios.id)
- motivo (nullable)
- creado_en

## Personal y asignaciones

### cuadrillas
- id (PK)
- nombre
- supervisor_id (FK → usuarios.id)

### tecnicos
- id (PK)
- usuario_id (FK → usuarios.id, único)
- cuadrilla_id (FK → cuadrillas.id)

### asignaciones
- id (PK)
- orden_id (FK → ordenes_trabajo.id)
- cuadrilla_id (FK → cuadrillas.id)
- tecnico_id (FK → tecnicos.id, nullable)
- estado (pendiente, aceptada, rechazada)
- motivo_rechazo (nullable)
- asignado_en

## Inventario y evidencias

### repuestos
- id (PK)
- codigo (único)
- nombre
- unidad
- existencia (no puede ser negativa)

### movimientos_repuestos
- id (PK)
- repuesto_id (FK → repuestos.id)
- orden_id (FK → ordenes_trabajo.id, nullable)
- tipo (entrada, salida, devolucion)
- cantidad
- usuario_id (FK → usuarios.id)
- creado_en

### evidencias
- id (PK)
- orden_id (FK → ordenes_trabajo.id)
- tipo (foto, documento)
- ruta_archivo
- descripcion
- subido_por (FK → usuarios.id)
- creado_en

## Relaciones principales
- Un cliente tiene muchos activos.
- Un activo tiene muchos incidentes y muchas órdenes de trabajo.
- Una orden de trabajo nace de un incidente y tiene un activo.
- Una orden tiene muchas asignaciones, muchos movimientos de repuestos y muchas evidencias.
- Una cuadrilla tiene muchos técnicos.