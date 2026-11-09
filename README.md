# POS Tienda — Sistema de Punto de Venta

Sistema de punto de venta desarrollado con **Flutter y Dart**, orientado a pequeños y medianos comercios, con gestión integral de ventas, inventario y operaciones comerciales.

Diseñado bajo un enfoque **offline-first**, utilizando SQLite para el almacenamiento local y Firebase para funcionalidades de sincronización y monitoreo remoto.

## Tecnologías utilizadas

- **Flutter y Dart** — Desarrollo de la aplicación de escritorio.
- **SQLite** — Persistencia local de información.
- **Firebase / Cloud Firestore** — Integración de servicios en la nube.
- **Provider** — Gestión del estado de la aplicación.
- **HTTP REST** — Comunicación con servicios externos.

## Funcionalidades principales

- **Punto de venta:** registro de ventas y control de operaciones.
- **Inventario:** productos, existencias, lotes y gestión FIFO.
- **Administración:** clientes, proveedores, gastos y mermas.
- **Créditos:** seguimiento de ventas a fiado y saldos pendientes.
- **Control de caja:** apertura, movimientos y cierre.
- **Usuarios y permisos:** roles de Administrador, Encargado y Cajero.
- **Reportes:** estadísticas de ventas, utilidades y productos más vendidos.
- **Auditoría:** seguimiento de operaciones realizadas en el sistema.
- **Configuración inicial:** registro del negocio y creación del usuario administrador.
- **Integración en la nube:** servicios de sincronización y monitoreo remoto en desarrollo.

## Arquitectura

El proyecto utiliza una estructura modular que separa modelos, servicios, proveedores de estado, interfaces y acceso a datos.

La aplicación está diseñada para mantener sus operaciones principales en una base de datos local, reduciendo la dependencia de una conexión permanente a internet.

## Estado del proyecto

**En desarrollo.** Las funcionalidades principales del sistema de escritorio están implementadas. La integración en la nube y la preparación para distribución comercial continúan en proceso.

## Capturas de pantalla


## 📸 Capturas de pantalla

### 🔐 Inicio de sesión
![Inicio de sesión](docs/screenshots/login.png)

### 🛒 Punto de venta
![Ventas - Pantalla principal](docs/screenshots/ventas1.png)
![Ventas - Segunda pantalla](docs/screenshots/ventas2.png)

### 📦 Gestión de productos
![Productos - Listado](docs/screenshots/productos1.png)
![Productos - Gestión](docs/screenshots/productos2.png)
![Productos - Detalles](docs/screenshots/productos3.png)

### 💰 Control de caja
![Caja - Pantalla principal](docs/screenshots/Caja.png)
![Caja - Segunda pantalla](docs/screenshots/caja2.png)

### 👥 Gestión de clientes
![Clientes](docs/screenshots/clientes.png)

### 🛍️ Gestión de compras
![Compras - Pantalla principal](docs/screenshots/compras1.png)
![Compras - Segunda pantalla](docs/screenshots/compras2.png)

### 🚚 Gestión de proveedores
![Proveedores](docs/screenshots/proveedores.png)

### 📉 Control de mermas
![Mermas](docs/screenshots/mermas.png)

### 📊 Reportes
![Reportes](docs/screenshots/Reportes.png)

### 👤 Administración de usuarios
![Usuarios](docs/screenshots/Usuarios.png)

### 🛡️ Auditoría
![Auditoría](docs/screenshots/Auditoria.png)

### ⚙️ Configuración del negocio
![Configuración - Pantalla principal](docs/screenshots/configuracion.png)
![Configuración - Segunda pantalla](docs/screenshots/configuracion2.png)

### ℹ️ Información del sistema
![Información](docs/screenshots/Informacion.png)


## Autor

Desarrollado como proyecto personal para aplicar conocimientos de desarrollo de software, bases de datos, arquitectura de aplicaciones y sistemas de gestión comercial.