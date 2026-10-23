-- Esquema: Centro de Operaciones de Campo, Activos e Incidentes

-- Seguridad y control de acceso
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE permisos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    contrasena_hash VARCHAR(255) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE roles_permisos (
    rol_id INT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permiso_id INT NOT NULL REFERENCES permisos(id) ON DELETE CASCADE,
    PRIMARY KEY (rol_id, permiso_id)
);

CREATE TABLE usuarios_roles (
    usuario_id INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    rol_id INT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (usuario_id, rol_id)
);

CREATE TABLE tokens (
    id SERIAL PRIMARY KEY,
    proposito VARCHAR(50) NOT NULL,
    referencia_tipo VARCHAR(30) NOT NULL,
    referencia_id INT NOT NULL,
    hash_token VARCHAR(255) NOT NULL UNIQUE,
    expira_en TIMESTAMPTZ NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'vigente'
        CHECK (estado IN ('vigente', 'usado', 'revocado', 'vencido')),
    creado_por INT NOT NULL REFERENCES usuarios(id),
    usado_en TIMESTAMPTZ
);

CREATE TABLE auditoria (
    id BIGSERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id) ON DELETE SET NULL,
    accion VARCHAR(50) NOT NULL,
    tabla VARCHAR(100) NOT NULL,
    registro_id INT,
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    ip VARCHAR(45),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Clientes y activos
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    direccion VARCHAR(255),
    latitud NUMERIC(9,6),
    longitud NUMERIC(9,6)
);

CREATE TABLE tipos_activo (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE activos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    tipo_activo_id INT NOT NULL REFERENCES tipos_activo(id),
    cliente_id INT NOT NULL REFERENCES clientes(id),
    ubicacion VARCHAR(255),
    estado VARCHAR(30) NOT NULL DEFAULT 'operativo'
        CHECK (estado IN ('operativo', 'en_falla', 'en_mantenimiento', 'fuera_de_servicio'))
);
CREATE INDEX idx_activos_cliente ON activos(cliente_id);

-- Incidentes y órdenes de trabajo
CREATE TABLE prioridades_sla (
    id SERIAL PRIMARY KEY,
    nivel VARCHAR(20) NOT NULL UNIQUE,
    tiempo_respuesta_horas INT NOT NULL CHECK (tiempo_respuesta_horas > 0),
    tiempo_resolucion_horas INT NOT NULL CHECK (tiempo_resolucion_horas > 0)
);

CREATE TABLE incidentes (
    id SERIAL PRIMARY KEY,
    activo_id INT NOT NULL REFERENCES activos(id),
    descripcion TEXT NOT NULL,
    reportado_por INT NOT NULL REFERENCES usuarios(id),
    fecha_reporte TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_incidentes_activo ON incidentes(activo_id);

CREATE TABLE ordenes_trabajo (
    id SERIAL PRIMARY KEY,
    incidente_id INT NOT NULL REFERENCES incidentes(id),
    activo_id INT NOT NULL REFERENCES activos(id),
    prioridad_id INT NOT NULL REFERENCES prioridades_sla(id),
    estado VARCHAR(30) NOT NULL DEFAULT 'creada'
        CHECK (estado IN ('creada', 'asignada', 'aceptada', 'en_proceso',
                          'pendiente_cierre', 'cerrada', 'rechazada')),
    diagnostico TEXT,
    solucion TEXT,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_inicio TIMESTAMPTZ,
    fecha_cierre TIMESTAMPTZ,
    aprobado_por INT REFERENCES usuarios(id)
);
CREATE INDEX idx_ordenes_estado ON ordenes_trabajo(estado);
CREATE INDEX idx_ordenes_activo ON ordenes_trabajo(activo_id);

CREATE TABLE historial_estados_orden (
    id SERIAL PRIMARY KEY,
    orden_id INT NOT NULL REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
    estado_anterior VARCHAR(30),
    estado_nuevo VARCHAR(30) NOT NULL,
    usuario_id INT NOT NULL REFERENCES usuarios(id),
    motivo TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cuadrillas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    supervisor_id INT REFERENCES usuarios(id)
);

CREATE TABLE tecnicos (
    id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
    cuadrilla_id INT REFERENCES cuadrillas(id)
);

CREATE TABLE asignaciones (
    id SERIAL PRIMARY KEY,
    orden_id INT NOT NULL REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
    cuadrilla_id INT NOT NULL REFERENCES cuadrillas(id),
    tecnico_id INT REFERENCES tecnicos(id),
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente'
        CHECK (estado IN ('pendiente', 'aceptada', 'rechazada')),
    motivo_rechazo TEXT,
    asignado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE repuestos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    unidad VARCHAR(20) NOT NULL,
    existencia NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (existencia >= 0)
);

CREATE TABLE movimientos_repuestos (
    id SERIAL PRIMARY KEY,
    repuesto_id INT NOT NULL REFERENCES repuestos(id),
    orden_id INT REFERENCES ordenes_trabajo(id),
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('entrada', 'salida', 'devolucion')),
    cantidad NUMERIC(12,2) NOT NULL CHECK (cantidad > 0),
    usuario_id INT NOT NULL REFERENCES usuarios(id),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE evidencias (
    id SERIAL PRIMARY KEY,
    orden_id INT NOT NULL REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('foto', 'documento')),
    ruta_archivo VARCHAR(500) NOT NULL,
    descripcion TEXT,
    subido_por INT NOT NULL REFERENCES usuarios(id),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);