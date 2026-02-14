# Bitacora del Proyecto (version humana)

## 0) Decision actual: AWS se queda en plan, no en deploy real

Por ahora no se desplegara en AWS para evitar costos recurrentes innecesarios en etapa de portafolio.

Que si se dejo listo:
- Plan detallado en `docs/aws-plan.md`.
- Pipeline y estructura para que el salto a AWS sea directo cuando convenga.
- Estrategia de costos y teardown para no gastar de mas.

Que no se hara por ahora:
- Crear recursos reales (ECR/ECS/ALB/CloudWatch/IAM) en cuenta AWS.
- Mantener servicios 24/7 cobrando mientras no aportan valor a la demo.

## 1) Que construimos y por que importa

Imagina que este proyecto es un antro con varias puertas:

- FastAPI es la pista principal donde pasa la accion.
- Docker Compose es el estacionamiento con dos filas separadas: DEV y QA.
- Kubernetes es el edificio con seguridad y reglas de entrada.
- Ingress es el letrero de la entrada que dice: `/dev` por una puerta y `/qa` por otra.
- GitHub Actions es el gerente que revisa calidad antes de abrir.
- GHCR es la bodega donde guardamos versiones del producto.

Resultado: tienes un flujo serio pero simple para demostrar practicas de DevOps reales.

## 2) Metaforas rapidas para entender componentes

### ClusterIP = el cadenero del antro

El cadenero no deja entrar a todo mundo desde la calle.
Solo deja pasar a quien ya esta adentro del edificio (dentro del cluster).
Eso evita que servicios internos queden expuestos sin querer.

### Ingress = recepcion con mapa de puertas

Llega una persona y pregunta: "vengo a /dev".
Recepcion la manda al equipo DEV.
Si dice "/qa", la manda al equipo QA.

### Health checks = checador de pulso

Cada cierto tiempo alguien pregunta: "sigues vivo?"
Si no responde bien, se reemplaza el contenedor.
Eso baja tiempo caido.

### CI = inspector de calidad

Antes de empaquetar, revisa lint y tests.
Si algo falla, no deja pasar el producto.

### CD con environments = doble filtro de seguridad

DEV pasa automatico en `main`.
QA pasa por ambiente protegido (aprobacion manual).
Es como tener un segundo filtro antes de abrir al publico.

## 3) Que ganamos con esto

- Menos "funciona en mi maquina".
- Versiones rastreables por tag (`latest`, `sha-...`).
- Separacion DEV/QA sin mezclar cambios.
- Despliegues mas repetibles y predecibles.
- Mejor trazabilidad cuando hay incidentes.

## 4) Riesgos que estamos evitando

- Publicar cambios sin pruebas.
- Exponer servicios internos por error.
- Sobrescribir versiones sin saber que se desplego.
- Dar permisos demasiado amplios al equipo equivocado.
- No tener forma de rollback logico por version.

## 5) Como se lo explicaria a una empresa

"No solo hicimos una API. Hicimos una linea de produccion."

- Desarrollo crea y valida en DEV.
- QA recibe una version controlada y aprobada.
- Cada imagen tiene huella digital (`sha`) para auditoria.
- Hay comandos de teardown para no dejar costos prendidos.

## 6) Como dar acceso a Dev y QA sin desorden

### En GitHub

- Team `dev-team`: write en repo.
- Team `qa-team`: read + aprobadores del environment `qa`.

### En GitHub Environments

- `dev`: sin aprobacion manual.
- `qa`: required reviewers (lideres QA), opcional wait timer.

### En AWS (cuando se implemente)

- Rol Dev: deploy solo a recursos DEV.
- Rol QA: ver logs QA y forzar redeploy QA sin cambiar imagen.

## 7) Ejemplo metaforico de incidente evitado

Caso: un dev sube cambio con bug a `main`.

Sin este sistema:
- Se despliega directo a QA o produccion sin filtro.
- QA pierde tiempo detectando tarde.

Con este sistema:
- CI lo frena si rompe tests/lint.
- Si pasa CI, QA aun tiene puerta protegida de aprobacion.
- Si hay problema, sabes exactamente que imagen (`sha`) se uso.

## 8) Checklist corto de operacion diaria

1. Verde en CI antes de hablar de despliegue.
2. Confirmar tag exacto en GHCR.
3. Desplegar a DEV primero.
4. QA aprueba despliegue a su ambiente.
5. Revisar logs y health.
6. Si no se usa, destruir recursos para evitar costo.

## 9) Que hace este sistema hoy (sin AWS)

- Levanta la API en local con dos ambientes (`dev` y `qa`) usando Docker Compose.
- Expone salud/version y genera logs con contexto (`env`, `version`, request path).
- Corre pruebas y lint en CI para bloquear cambios rotos.
- Construye y publica imagenes en GHCR con tags trazables (`latest` y `sha-*`).
- Ejecuta CD con environments: DEV automatico y QA manual con aprobacion.
- Permite destruir todo local con un solo comando para no dejar basura corriendo.

## 10) Skills que este proyecto showcasea

- Backend API design: endpoints de estado/version y middleware de logging.
- Containerization: Dockerfile limpio y Compose por ambientes.
- Testing y quality gates: pytest + ruff + black.
- Kubernetes fundamentals: namespace, deployment, service, probes e ingress con rutas.
- CI/CD engineering: workflows separados para CI y CD con promotions por environment.
- Release traceability: versionado por tags inmutables (`sha`).
- Operacion y soporte: observabilidad basica, troubleshooting y teardown seguro.
- Documentacion tecnica y funcional: guias para perfiles tecnicos y no tecnicos.
