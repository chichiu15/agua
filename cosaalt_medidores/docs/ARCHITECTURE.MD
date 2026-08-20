Arquitectura Frontend — COSAALT Módulo Medidores

1. Objetivo del proyecto

La aplicación COSAALT - Módulo Medidores digitaliza el proceso de asignación y ejecución de cambios de medidores que actualmente se realiza mediante planillas físicas.

El sistema móvil contempla dos roles principales:

- Asignador: visualiza solicitudes, arma recorridos, asigna trabajo y supervisa el avance.
- Técnico: recibe su recorrido, ejecuta el cambio de medidor, registra los datos y posteriormente sincroniza la información.

La aplicación está desarrollada con Flutter y consume una API .NET, la cual funciona como intermediaria entre Flutter y la base de datos SQL Server.

---

2. Visión general de la arquitectura

┌───────────────────────────────┐
│          FLUTTER APP          │
│                               │
│  Pantallas + Estado + Lógica  │
└───────────────┬───────────────┘
                │
                │ HTTP / JSON
                ▼
┌───────────────────────────────┐
│          API .NET             │
│                               │
│ Controllers / DTOs / Services │
│ Repositories / Mappers        │
└───────────────┬───────────────┘
                │
                │ Entity Framework
                ▼
┌───────────────────────────────┐
│       SQL SERVER COSAALT      │
│                               │
│ Socios / Medidores / ODECO    │
│ Lecturas / Rutas / Usuarios   │
└───────────────────────────────┘

Flutter no debe conocer directamente la estructura física de SQL Server.

Por ejemplo, Flutter no debería depender de nombres como:

Reg_soc
Nom_soc
Catastral_soc
Nro_hoja_solicitudLec

La API .NET transforma esos datos mediante DTOs y Mappers antes de enviarlos a Flutter.

De esta manera, si COSAALT modifica posteriormente una columna de la base de datos, el cambio se resuelve principalmente en el backend sin tener que rediseñar toda la aplicación móvil.

---

3. Arquitectura utilizada en Flutter

Se utiliza una arquitectura:

Feature-First
+
Separación Data / Domain / Presentation
+
Repository Pattern
+
Inyección de dependencias

La regla general es:

┌──────────────────────┐
│      PRESENTATION    │
│ Pantallas / Widgets  │
│ Controllers          │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│        DOMAIN        │
│ Entidades            │
│ Contratos            │
│ Reglas del negocio   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│         DATA         │
│ API / JSON / SQLite  │
│ Repository Impl.     │
└──────────────────────┘

Una pantalla nunca debe acceder directamente a la API o a SQLite.

Ejemplo correcto:

LoginScreen
     │
     ▼
AuthController
     │
     ▼
AuthRepository
     │
     ├────────► MockAuthRepository      ← actualmente
     │
     └────────► ApiAuthRepository       ← posteriormente

---

4. Árbol actual del proyecto

cosaalt_medidores/
│
├── android/
│   └── Configuración específica de Android.
│
├── windows/
│   └── Configuración específica de Windows.
│
├── assets/
│   │
│   └── images/
│       └── logo_cosaalt.png
│
├── docs/
│   └── ARCHITECTURE.md
│
├── lib/
│   │
│   ├── app/
│   │   │
│   │   ├── app.dart
│   │   │
│   │   └── router/
│   │       └── app_router.dart
│   │
│   ├── core/
│   │   │
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   └── app_theme.dart
│   │   │
│   │   └── widgets/
│   │       └── dashboard_widgets.dart
│   │
│   ├── features/
│   │   │
│   │   ├── auth/
│   │   │   │
│   │   │   ├── data/
│   │   │   │   └── repositories/
│   │   │   │       └── mock_auth_repository.dart
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   │
│   │   │   │   ├── entities/
│   │   │   │   │
│   │   │   │   └── repositories/
│   │   │   │
│   │   │   └── presentation/
│   │   │       │
│   │   │       ├── controllers/
│   │   │       │
│   │   │       └── screens/
│   │   │
│   │   └── home/
│   │       └── presentation/
│   │           └── screens/
│   │
│   └── main.dart
│
├── pubspec.yaml
└── README.md

---

5. ¿Qué va dentro de cada carpeta?

"assets/"

Contiene archivos que forman parte de la aplicación pero no son código Dart.

assets/
├── images/
├── icons/        ← futuro
└── mocks/        ← futuro

Ejemplos:

assets/images/logo_cosaalt.png
assets/icons/
assets/mocks/solicitudes.json

Los assets deben declararse en:

pubspec.yaml

---

6. Carpeta "lib/app/"

Contiene la configuración principal de la aplicación.

app/
├── app.dart
└── router/
    └── app_router.dart

"app.dart"

Es el punto donde se configura:

- "MaterialApp"
- tema visual
- Router
- título de la aplicación
- configuración global

Flujo:

main.dart
   │
   ▼
CosaaltApp
   │
   ├── Theme
   └── Router

"router/"

Contiene las rutas globales.

Actualmente:

/login
/asignador
/tecnico

También se encarga de proteger las rutas según el rol.

Ejemplo:

usuario no autenticado
        │
        ▼
      /login


usuario ASIGNADOR
        │
        ▼
   /asignador


usuario TÉCNICO
        │
        ▼
    /tecnico

Un técnico no debe poder ingresar accidentalmente a:

/asignador

y viceversa.

---

7. Carpeta "lib/core/"

Contiene elementos reutilizables por distintos módulos.

core/
├── theme/
└── widgets/

En el futuro puede crecer a:

core/
├── constants/
├── errors/
├── network/
├── storage/
├── theme/
├── utils/
└── widgets/

"core/theme/"

Contiene toda la identidad visual global.

theme/
├── app_colors.dart
└── app_theme.dart

"app_colors.dart"

Centraliza la paleta COSAALT.

Ninguna pantalla debería repetir manualmente valores como:

Color(0xFF20972F)

En su lugar:

AppColors.primaryGreen

Así, si el color institucional cambia, solamente se modifica un archivo.

"app_theme.dart"

Configura estilos globales para:

- TextFields
- botones
- AppBars
- fondos
- colores principales
- bordes
- formularios

---

8. Sistema visual COSAALT

La interfaz mantiene la identidad definida en los bosquejos del proyecto.

Colores principales

Verde principal COSAALT
#20972F

Verde secundario
#52B65F

Azul corporativo
#2A3283

Celeste de tarjetas
#D1EFF9

Celeste de acciones
#37CCF7

Rojo ODECO / Error
#FF0004

Amarillo del logo
#FFFF00

Fondo
#F5F5F5

Blanco
#FFFFFF

Uso recomendado:

VERDE
│
├── encabezados
├── identidad
├── navegación activa
└── estados exitosos

AZUL
│
├── títulos
├── textos corporativos
└── iconografía secundaria

CELESTE
│
├── tarjetas
├── información secundaria
└── acciones

ROJO
│
├── solicitudes ODECO
├── errores
└── urgencias

AMARILLO
│
└── acento visual relacionado con el logo

---

9. Carpeta "lib/core/widgets/"

Guarda widgets reutilizados en varios módulos.

Actualmente:

dashboard_widgets.dart

Contiene componentes como:

CosaaltAppBar
SummaryMetricCard
QuickActionTile
CosaaltBottomNav

Regla:

Si un componente aparece en varias pantallas, debería evaluarse moverlo a "core/widgets".

Ejemplo:

Dashboard Asignador
        │
        ├── CosaaltAppBar
        ├── SummaryMetricCard
        └── CosaaltBottomNav


Dashboard Técnico
        │
        ├── CosaaltAppBar
        ├── SummaryMetricCard
        └── CosaaltBottomNav

Así se evita duplicar código.

---

10. Carpeta "features/"

Aquí vive la funcionalidad real del sistema.

Cada módulo se organiza independientemente.

Actualmente:

features/
├── auth/
└── home/

Futuro:

features/
├── auth/
├── home/
├── solicitudes/
├── rutas/
├── ejecucion_cambio/
├── evidencias/
├── historial/
├── sincronizacion/
├── catalogos/
└── usuarios/

Cada funcionalidad puede contener:

feature/
├── data/
├── domain/
└── presentation/

---

11. Capa "domain"

Ejemplo:

features/auth/domain/
├── entities/
└── repositories/

La capa Domain representa las reglas y conceptos de negocio.

No debería depender directamente de:

Flutter UI
Dio
HTTP
SQLite
SQL Server
Windows
Android

"entities/"

Contiene objetos propios del dominio.

Ejemplo:

AppUser

Conceptualmente:

AppUser
├── id
├── username
├── fullName
├── role
└── active

"repositories/"

Define contratos.

Ejemplo:

AuthRepository

El contrato dice:

"Necesito una función login"

pero no especifica de dónde vienen los datos.

---

12. Capa "data"

La capa Data obtiene realmente la información.

Actualmente:

data/
└── repositories/
    └── mock_auth_repository.dart

Hoy:

AuthRepository
       │
       ▼
MockAuthRepository

Posteriormente:

AuthRepository
       │
       ▼
ApiAuthRepository
       │
       ▼
AuthRemoteDataSource
       │
       ▼
API .NET

De esta manera la interfaz no cambia cuando se reemplazan los mocks por la API.

---

13. Capa "presentation"

Contiene aquello relacionado directamente con la interfaz.

presentation/
├── controllers/
├── screens/
└── widgets/       ← cuando sea necesario

"screens/"

Pantallas completas.

Ejemplo:

login_screen.dart
asignador_dashboard_screen.dart
tecnico_dashboard_screen.dart

"controllers/"

Controlan el estado y coordinan acciones.

Actualmente se utiliza Riverpod.

Ejemplo:

LoginScreen
     │
     │ usuario + contraseña
     ▼
AuthController
     │
     ▼
AuthRepository

La pantalla se dedica principalmente a mostrar información.

El Controller coordina la acción.

---



14. Flujo actual del Login

Actualmente se utiliza un repositorio MOCK.

┌──────────────────┐
│   LoginScreen    │
└────────┬─────────┘
         │
         │ login()
         ▼
┌──────────────────┐
│  AuthController  │
└────────┬─────────┘
         │
         │ repository.login()
         ▼
┌──────────────────┐
│  AuthRepository  │
└────────┬─────────┘
         │
         ▼
┌──────────────────────┐
│ MockAuthRepository   │
└──────────┬───────────┘
           │
           ▼
       AppUser
           │
           ▼
┌──────────────────┐
│    GoRouter      │
└────────┬─────────┘
         │
         ├── asignador → /asignador
         │
         └── tecnico   → /tecnico

---

15. Flujo futuro del Login con backend

Cuando se conecte la API:

LoginScreen
      │
      ▼
AuthController
      │
      ▼
AuthRepository
      │
      ▼
ApiAuthRepository
      │
      ▼
AuthRemoteDataSource
      │
      ▼
POST /Auth/Login
      │
      ▼
API .NET
      │
      ▼
JWT + datos usuario

Posteriormente el JWT deberá almacenarse en almacenamiento seguro.

El objetivo es que para conectar la API no sea necesario modificar LoginScreen.

---

16. Flujo esperado de solicitudes y rutas

Asignador

LOGIN
  │
  ▼
DASHBOARD ASIGNADOR
  │
  ├── Ver solicitudes
  │
  ▼
Seleccionar solicitudes
  │
  ▼
Armar recorrido
  │
  ▼
Ordenar recorrido
  │
  ▼
Seleccionar técnico
  │
  ▼
Asignar ruta
  │
  ▼
Monitorear avance

Técnico

LOGIN
  │
  ▼
DASHBOARD TÉCNICO
  │
  ▼
Descargar ruta del día
  │
  ▼
Trabajar solicitud
  │
  ▼
Registrar cambio
  │
  ├── Medidor retirado
  ├── Lectura
  ├── Motivo
  ├── Medidor instalado
  ├── Observaciones
  └── Fotografías
  │
  ▼
GUARDAR LOCALMENTE
  │
  ▼
SINCRONIZAR
  │
  ▼
API .NET

---

17. Arquitectura Offline futura

El técnico debe poder continuar trabajando incluso cuando pierde la conexión.

Por ello el flujo futuro será:

            INTERNET
                │
                ▼
         Descargar ruta
                │
                ▼
┌─────────────────────────┐
│ Base de datos local     │
│ SQLite / alternativa    │
└────────────┬────────────┘
             │
        SIN INTERNET
             │
             ▼
       Técnico trabaja
             │
             ▼
       Guarda cambios
             │
             ▼
         Pendientes
             │
     vuelve INTERNET
             ▼
        Sincronizar
             │
             ▼
           API

---


18. Convenciones del proyecto

Archivos Dart

Utilizar:

snake_case.dart

Ejemplo:

auth_controller.dart
login_screen.dart
app_colors.dart

Clases

Utilizar:

PascalCase

Ejemplo:

AuthController
LoginScreen
AppUser

Variables y métodos

Utilizar:

camelCase

Ejemplo:

currentUser
isLoading
login()

---

19. Regla para agregar nuevas funcionalidades

Antes de crear un archivo, preguntarse:

¿Pertenece solamente a una funcionalidad?
        │
        ├── SÍ → features/nombre_feature/
        │
        └── NO
             │
             ▼
¿Se reutiliza en muchas funcionalidades?
        │
        ├── SÍ → core/
        └── NO → revisar responsabilidad

Ejemplo:

Un formulario exclusivamente de cambio de medidor:

features/ejecucion_cambio/

Un botón genérico utilizado por todo el sistema:

core/widgets/

---

20. Regla fundamental de acceso a datos

Nunca hacer esto dentro de una pantalla:

Pantalla
   │
   └────────────► API

Utilizar:

Pantalla
   │
   ▼
Controller
   │
   ▼
Repository
   │
   ▼
Data Source
   │
   ▼
API / SQLite / Mock

---

21. Regla respecto a SQL Server

Flutter no debe contener nombres de columnas provenientes directamente de la base de datos institucional.

Incorrecto:

Reg_soc
Nom_soc
Direc_soc

Correcto dentro de Flutter:

registrationNumber
fullName
address

La traducción debe realizarse mediante el backend y los modelos correspondientes.

---



----Usuarios temporales MOCKEADOS LOGIN
Usuario:
asignador
Contraseña:
123456

Usuario:
tecnico1
Contraseña:
123456