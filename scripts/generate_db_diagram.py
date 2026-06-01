#!/usr/bin/env python3
"""Generate physical database model diagram for HimnarioID 2.0."""
import sys
try:
    from graphviz import Digraph
except ImportError:
    print("ERROR: graphviz Python package not installed. Install with: pip install graphviz")
    sys.exit(1)

# Generate the physical database model
dot = Digraph(
    name='HimnarioID_DB',
    format='png',
    graph_attr={
        'rankdir': 'LR',
        'bgcolor': '#1a1a2e',
        'fontcolor': 'white',
        'fontsize': '16',
        'label': 'HimnarioID 2.0 - Modelo Fisico de Base de Datos',
        'labelloc': 't',
        'dpi': '150',
        'pad': '0.5',
        'splines': 'true',
    },
    node_attr={
        'shape': 'record',
        'style': 'filled,rounded',
        'fontname': 'Arial',
        'fontsize': '11',
    },
    edge_attr={
        'color': '#88cccc',
        'fontcolor': '#88cccc',
        'fontsize': '9',
        'penwidth': '1.5',
    }
)

# Style configurations
table_bg = '#16213e'
pk_bg = '#0f3460'

def add_table(name, columns, table_color=table_bg):
    """Add a table with columns."""
    label = '<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="6" BGCOLOR="' + table_color + '">'
    label += '<TR><TD COLSPAN="2" BGCOLOR="' + pk_bg + '"><FONT COLOR="white" POINT-SIZE="12"><B>' + name + '</B></FONT></TD></TR>'
    for col_name, col_type, _ in columns:
        font_color = '#e0e0e0'
        prefix = ''
        if col_name.startswith('PK '):
            col_name = col_name[3:]
            font_color = '#ffd700'
            prefix = '🔑 '
        elif col_name.startswith('FK '):
            col_name = col_name[3:]
            font_color = '#88ccff'
            prefix = '🔗 '
        label += '<TR><TD ALIGN="LEFT" BGCOLOR="' + table_color + '"><FONT COLOR="' + font_color + '">' + prefix + col_name + '</FONT></TD>'
        label += '<TD ALIGN="CENTER" BGCOLOR="' + table_color + '"><FONT COLOR="#e0e0e0">' + col_type + '</FONT></TD></TR>'
    label += '</TABLE>'
    dot.node(name, '<' + label + '>', shape='plaintext')


# ============================================
# TABLAS MAESTRAS
# ============================================

add_table('Himno', [
    ('PK id', 'INTEGER', 'PK'),
    ('titulo_principal', 'TEXT', 'NOT NULL'),
    ('numero_oficial', 'INTEGER', ''),
    ('tipo', 'INTEGER', 'CHECK(1,2,3)'),
    ('activo', 'INTEGER', 'DEFAULT 1'),
    ('fecha_creacion', 'TEXT', 'DEFAULT now'),
])

add_table('Version_Pais', [
    ('PK id', 'INTEGER', 'PK'),
    ('FK himno_id', 'INTEGER', 'FK to Himno'),
    ('pais', 'TEXT', 'NOT NULL'),
    ('tonalidad_original', 'TEXT', "DEFAULT 'C'"),
    ('activo', 'INTEGER', 'DEFAULT 1'),
])

add_table('Estrofa', [
    ('PK id', 'INTEGER', 'PK'),
    ('FK version_pais_id', 'INTEGER', 'FK to Version_Pais'),
    ('tipo', 'TEXT', "CHECK tipòs"),
    ('orden', 'INTEGER', 'NOT NULL'),
    ('contenido', 'TEXT', 'ChordPro'),
])

# ============================================
# CATEGORIZACION N:M
# ============================================

add_table('Categoria', [
    ('PK id', 'INTEGER', 'PK'),
    ('nombre', 'TEXT', 'UNIQUE'),
])

add_table('Himno_Categoria', [
    ('FK himno_id', 'INTEGER', 'FK to Himno'),
    ('FK categoria_id', 'INTEGER', 'FK to Categoria'),
])

# ============================================
# SISTEMA DE FORKS
# ============================================

add_table('Usuario', [
    ('PK id', 'INTEGER', 'PK'),
    ('username', 'TEXT', 'UNIQUE'),
    ('password_hash', 'TEXT', 'NOT NULL'),
    ('nombre', 'TEXT', 'NOT NULL'),
    ('rol', 'TEXT', "CHECK roles"),
    ('fecha_registro', 'TEXT', 'DEFAULT now'),
])

add_table('Arreglo_Musical', [
    ('PK id', 'INTEGER', 'PK'),
    ('FK version_pais_id', 'INTEGER', 'FK to Version_Pais'),
    ('FK usuario_id', 'INTEGER', 'FK to Usuario'),
    ('nombre_arreglo', 'TEXT', 'NOT NULL'),
    ('tonalidad_base', 'TEXT', 'NOT NULL'),
    ('version', 'INTEGER', 'DEFAULT 1'),
    ('fecha_creacion', 'TEXT', 'DEFAULT now'),
    ('fecha_modificacion', 'TEXT', 'DEFAULT now'),
])

add_table('Estrofa_Arreglo', [
    ('PK id', 'INTEGER', 'PK'),
    ('FK arreglo_musical_id', 'INTEGER', 'FK to Arreglo_Musical'),
    ('tipo', 'TEXT', "CHECK tipòs"),
    ('orden', 'INTEGER', 'NOT NULL'),
    ('contenido', 'TEXT', 'ChordPro editado'),
])

# ============================================
# MULTIMEDIA
# ============================================

add_table('Pista_Audio', [
    ('PK id', 'INTEGER', 'PK'),
    ('FK himno_id', 'INTEGER', 'FK to Himno'),
    ('ruta_archivo', 'TEXT', 'NOT NULL'),
    ('descripcion', 'TEXT', ''),
    ('origen', 'TEXT', "DEFAULT 'local'"),
    ('duracion_segundos', 'REAL', ''),
    ('formato', 'TEXT', ''),
    ('FK usuario_donante_id', 'INTEGER', 'FK to Usuario'),
])

add_table('Fondo_Pantalla', [
    ('PK id', 'INTEGER', 'PK'),
    ('nombre', 'TEXT', 'NOT NULL'),
    ('tipo', 'TEXT', "CHECK tipos"),
    ('ruta_archivo', 'TEXT', ''),
    ('color_hex', 'TEXT', ''),
    ('es_predeterminado', 'INTEGER', 'DEFAULT 0'),
    ('activo', 'INTEGER', 'DEFAULT 1'),
])

# ============================================
# CONFIGURACION E HISTORIAL
# ============================================

add_table('Configuracion', [
    ('PK clave', 'TEXT', 'PK'),
    ('valor', 'TEXT', 'NOT NULL'),
])

add_table('Historial_Reproduccion', [
    ('PK id', 'INTEGER', 'PK'),
    ('FK himno_id', 'INTEGER', 'FK to Himno'),
    ('FK version_pais_id', 'INTEGER', 'FK to Version_Pais'),
    ('timestamp', 'TEXT', 'DEFAULT now'),
])

# ============================================
# RELACIONES
# ============================================

# Master tables
dot.edge('Himno', 'Version_Pais', label='1 a N', arrowhead='diamond')
dot.edge('Version_Pais', 'Estrofa', label='1 a N', arrowhead='diamond')
dot.edge('Himno', 'Historial_Reproduccion', label='1 a N', arrowhead='diamond')

# N:M
dot.edge('Himno', 'Himno_Categoria', label='1 a N', arrowhead='diamond')
dot.edge('Categoria', 'Himno_Categoria', label='1 a N', arrowhead='diamond')

# Fork system
dot.edge('Version_Pais', 'Arreglo_Musical', label='1 a N', arrowhead='diamond')
dot.edge('Usuario', 'Arreglo_Musical', label='1 a N', arrowhead='diamond')
dot.edge('Arreglo_Musical', 'Estrofa_Arreglo', label='1 a N', arrowhead='diamond')

# Multimedia
dot.edge('Himno', 'Pista_Audio', label='1 a N', arrowhead='diamond')
dot.edge('Usuario', 'Pista_Audio', label='1 a N', arrowhead='diamond', style='dashed')

# Save
output_path = '/home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0/capturas/modelo_fisico_db'
dot.render(output_path, cleanup=True)
print(f'OK: Diagrama generado en: {output_path}.png')
print(f'Size: {__import__("os").path.getsize(output_path + ".png")} bytes')
