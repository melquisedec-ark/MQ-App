-- ============================================
-- ESQUEMA DE BASE DE DATOS - HimnarioID 2.0
-- Motor: SQLite
-- Versión: 1.0.0
-- ============================================

-- ============================================
-- TABLAS MAESTRAS
-- ============================================

CREATE TABLE Himno (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  titulo_principal TEXT NOT NULL,
  numero_oficial INTEGER,
  tipo INTEGER NOT NULL CHECK(tipo IN (1, 2, 3)), -- 1=Oficial, 2=Inspirada, 3=Convención
  evento TEXT,  -- Evento al que pertenece (ej: "I Convención", "II Campamento Juvenil Nacional")
  activo INTEGER NOT NULL DEFAULT 1,
  fecha_creacion TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_himno_numero ON Himno(numero_oficial);
CREATE INDEX idx_himno_activo ON Himno(activo);

CREATE TABLE Pais (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL UNIQUE,
  codigo TEXT
);

CREATE TABLE Version_Pais (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  himno_id INTEGER NOT NULL,
  pais_id INTEGER NOT NULL REFERENCES Pais(id),
  tonalidad_original TEXT NOT NULL DEFAULT 'C',  -- ej. "G", "C#m"
  activo INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE
);
CREATE INDEX idx_version_himno ON Version_Pais(himno_id);
CREATE UNIQUE INDEX idx_version_pais_unica ON Version_Pais(himno_id, pais_id);

CREATE TABLE Estrofa (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  version_pais_id INTEGER NOT NULL,
  tipo TEXT NOT NULL CHECK(tipo IN ('Coro', 'Estrofa', 'Puente', 'Intro', 'Final')),
  orden INTEGER NOT NULL,
  contenido TEXT NOT NULL,  -- Formato ChordPro
  FOREIGN KEY (version_pais_id) REFERENCES Version_Pais(id) ON DELETE CASCADE
);
CREATE INDEX idx_estrofa_version ON Estrofa(version_pais_id, orden);

-- ============================================
-- CATEGORIZACIÓN N:M
-- ============================================

CREATE TABLE Categoria (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL UNIQUE
);

CREATE TABLE Himno_Categoria (
  himno_id INTEGER NOT NULL,
  categoria_id INTEGER NOT NULL,
  PRIMARY KEY (himno_id, categoria_id),
  FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE,
  FOREIGN KEY (categoria_id) REFERENCES Categoria(id) ON DELETE CASCADE
);
CREATE INDEX idx_hc_categoria ON Himno_Categoria(categoria_id);

-- ============================================
-- SISTEMA DE FORKS (ARREGLOS PERSONALIZADOS)
-- ============================================

CREATE TABLE Usuario (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  nombre TEXT NOT NULL,
  rol TEXT NOT NULL DEFAULT 'Musico' CHECK(rol IN ('Admin', 'Musico', 'Visualizador')),
  fecha_registro TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE Arreglo_Musical (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  version_pais_id INTEGER NOT NULL,
  usuario_id INTEGER NOT NULL,
  nombre_arreglo TEXT NOT NULL,
  tonalidad_base TEXT NOT NULL,
  version INTEGER NOT NULL DEFAULT 1,
  fecha_creacion TEXT NOT NULL DEFAULT (datetime('now')),
  fecha_modificacion TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (version_pais_id) REFERENCES Version_Pais(id) ON DELETE CASCADE,
  FOREIGN KEY (usuario_id) REFERENCES Usuario(id) ON DELETE CASCADE
);
CREATE INDEX idx_arreglo_usuario ON Arreglo_Musical(usuario_id);

CREATE TABLE Estrofa_Arreglo (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  arreglo_musical_id INTEGER NOT NULL,
  tipo TEXT NOT NULL CHECK(tipo IN ('Coro', 'Estrofa', 'Puente', 'Intro', 'Final')),
  orden INTEGER NOT NULL,
  contenido TEXT NOT NULL,  -- ChordPro editado
  FOREIGN KEY (arreglo_musical_id) REFERENCES Arreglo_Musical(id) ON DELETE CASCADE
);
CREATE INDEX idx_estrofa_arreglo ON Estrofa_Arreglo(arreglo_musical_id, orden);

-- ============================================
-- MULTIMEDIA
-- ============================================

CREATE TABLE Pista_Audio (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  himno_id INTEGER NOT NULL,
  ruta_archivo TEXT NOT NULL,
  descripcion TEXT,
  origen TEXT NOT NULL DEFAULT 'local',  -- 'local', 'network', 'asset'
  duracion_segundos REAL,
  formato TEXT,
  usuario_donante_id INTEGER,
  FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE,
  FOREIGN KEY (usuario_donante_id) REFERENCES Usuario(id) ON DELETE SET NULL
);
CREATE INDEX idx_pista_himno ON Pista_Audio(himno_id);

-- ============================================
-- CONFIGURACIÓN E HISTORIAL
-- ============================================

CREATE TABLE Configuracion (
  clave TEXT PRIMARY KEY,
  valor TEXT NOT NULL
);

CREATE TABLE Historial_Reproduccion (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  himno_id INTEGER NOT NULL,
  version_pais_id INTEGER,
  timestamp TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE
);
CREATE INDEX idx_historial_timestamp ON Historial_Reproduccion(timestamp DESC);

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista: himnos con su información principal
CREATE VIEW IF NOT EXISTS v_himno_resumen AS
SELECT
  h.id,
  h.titulo_principal,
  h.numero_oficial,
  h.tipo,
  h.activo,
  p.nombre AS pais,
  vp.tonalidad_original
FROM Himno h
LEFT JOIN Version_Pais vp ON vp.himno_id = h.id AND vp.activo = 1
LEFT JOIN Pais p ON p.id = vp.pais_id
ORDER BY h.numero_oficial;

-- ============================================
-- FONDOS DE PANTALLA
-- ============================================

CREATE TABLE Fondo_Pantalla (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  tipo TEXT NOT NULL CHECK(tipo IN ('imagen', 'color_solido')),
  ruta_archivo TEXT,
  color_hex TEXT,
  es_predeterminado INTEGER NOT NULL DEFAULT 0,
  activo INTEGER NOT NULL DEFAULT 1
);

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista: conteo de estrofas por himno
CREATE VIEW IF NOT EXISTS v_himno_estrofas AS
SELECT
  vp.himno_id,
  vp.id AS version_pais_id,
  COUNT(e.id) AS total_estrofas,
  SUM(CASE WHEN e.tipo = 'Coro' THEN 1 ELSE 0 END) AS total_coros
FROM Version_Pais vp
LEFT JOIN Estrofa e ON e.version_pais_id = vp.id
GROUP BY vp.id;
