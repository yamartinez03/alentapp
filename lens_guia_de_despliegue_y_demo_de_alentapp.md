# Guía de Despliegue y Demo de AlentApp

> **Nota:** Si `kind get clusters` ya lista `lens-demo`, puedes pasar directamente a la **Sección 2**.

---

## 1. Armar todo desde cero (Primera vez)

### 1.1 Docker Desktop corriendo
Abre Docker Desktop y espera a que el estado indique **"Engine running"**.

### 1.2 Crear el cluster (3 nodos)
Crea un archivo llamado `kind-cluster.yaml` en la raíz del repositorio con el siguiente contenido:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: lens-demo
nodes:
  - role: control-plane
  - role: worker
  - role: worker
```

Ejecuta el siguiente comando en PowerShell para crear el cluster y verificar los nodos:

```powershell
kind create cluster --config kind-cluster.yaml
kubectl get nodes        # Tienen que verse 3 nodos en estado Ready
```

### 1.3 Instalar metrics-server y agregarle `--kubelet-insecure-tls`
> **Importante para PowerShell:** No uses `\"` para escapar comillas. Utiliza un archivo de parche (`patch.json`).

```powershell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

'[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' | Out-File -Encoding utf8 -NoNewline patch.json
kubectl patch deployment metrics-server -n kube-system --type=json --patch-file=patch.json
```

Verifica que el flag se aplicó correctamente y que el servicio responde (puede tardar 1-2 minutos):

```powershell
kubectl get deployment metrics-server -n kube-system -o jsonpath='{.spec.template.spec.containers[0].args}'
kubectl rollout status deployment metrics-server -n kube-system
kubectl top nodes        # Tiene que devolver métricas de uso de CPU y memoria
```

### 1.4 Construir las imágenes de PRODUCCIÓN y cargarlas en el cluster
El cluster creado en el paso 1.2 debe existir previamente, ya que el script finaliza con `kind load`. Desde **Git Bash**, ubicado en la raíz del repositorio, ejecuta:

```bash
./scripts/01-build-and-load-images.sh
```

Esto ejecuta internamente los siguientes comandos:

```bash
docker build -t alentapp-backend:prod  -f packages/api/Dockerfile.prod .
docker build -t alentapp-frontend:prod -f packages/web/Dockerfile.prod .
kind load docker-image alentapp-backend:prod  --name lens-demo
kind load docker-image alentapp-frontend:prod --name lens-demo
```

*La primera vez el proceso tardará varios minutos debido al `npm install` del monorepo dentro de Docker.*

> **Requisito del `Dockerfile.prod` del frontend:** Asegúrate de que contenga esta línea antes de la directiva `USER nginx` para permitir que Nginx escriba su archivo `pid`:
> ```dockerfile
> RUN sed -i 's#/run/nginx.pid#/tmp/nginx.pid#' /etc/nginx/nginx.conf
> ```

### 1.5 Verificar que las imágenes se cargaron correctamente

```powershell
docker images | findstr alentapp                                      # En tu Docker local
docker exec lens-demo-worker crictl images | findstr alentapp    # Adentro del nodo (opcional)
```
*Si las imágenes no figuran dentro del nodo, los pods se quedarán en estado `ImagePullBackOff`.*

### 1.6 Desplegar la infraestructura base
Aplica los manifiestos YAML ubicados en la carpeta de despliegue (`alentapp-demo` o equivalente):

```powershell
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-db-postgres.yaml
kubectl wait --for=condition=Ready pod -l app=db -n alentapp --timeout=60s
```

### 1.7 Migrar la base de datos (Única vez; el PVC conservará las tablas)
Requiere que el pod de la base de datos esté `Ready`. Desde **Git Bash**, parado en la raíz del repo:

```bash
./scripts/00-migrate-db.sh
```

**Por qué se realiza de esta manera:**
- **Puerto 5433:** Evita conflictos si ya usas el puerto `5432` con una instancia local de PostgreSQL.
- **`prisma@7.8.0`:** Fija la versión para evitar cambios abruptos en la sintaxis de los comandos de migración.

Para verificar que las tablas se crearon correctamente:

```powershell
kubectl exec -n alentapp deployment/db -- psql -U admin -d alentapp_db -c "\dt"
```

### 1.8 Desplegar Backend y Frontend

```powershell
kubectl apply -f 02-backend.yaml
kubectl apply -f 03-frontend.yaml
kubectl get pods -n alentapp -o wide --watch      # Presiona Ctrl+C al finalizar
```
*Resultado esperado:* **5 pods en Running** (1 pod `db` en el control-plane, 2 pods de `backend` y 2 pods de `frontend`).

### 1.9 Conectar Lens
1. En Lens, ve a *Local Kubeconfigs* → **"+"** → *Add kubeconfig from filesystem* → selecciona `C:\Users\<tu-usuario>\.kube\config`.
2. Ingresa al cluster **`kind-lens-demo`** (verás el punto verde de conexión).
3. Dirígete a *Workloads → Pods* y cambia el filtro superior de espacios de nombres (`namespace`) de `default` a **`alentapp`**.

---

## 2. Cada vez: Levantar la demo (Entorno ya configurado)

### 2.1 Iniciar Docker Desktop
Abre Docker Desktop y aguarda hasta ver el mensaje **"Engine running"**.

### 2.2 Verificar que el cluster esté activo

```powershell
kind get clusters         # Debe listar lens-demo
kubectl get nodes        # Los 3 nodos deben estar Ready
```

Si `kubectl` no responde, es probable que los contenedores de los nodos hayan quedado detenidos al apagar el equipo:

```powershell
docker ps -a --filter "name=lens-demo"
docker start lens-demo-control-plane lens-demo-worker lens-demo-worker2
# Espera aproximadamente 1 minuto y valida de nuevo con: kubectl get nodes
```

### 2.3 Verificar el estado de la aplicación

```powershell
kubectl get pods -n alentapp -o wide
```
- Si visualizas los **5 pods en Running**, no es necesario redesplegar ni volver a migrar.

### 2.4 Abrir los accesos de red
Ejecuta el siguiente comando para levantar los puertos de manera automática con reconexión:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\04-iniciar-demo.ps1
```
*Esto abrirá dos ventanas independientes para mantener los servicios enlazados:*
- **Frontend:** <http://localhost:8080>
- **Backend:** <http://localhost:3000>

### 2.5 Monitoreo con Lens y Navegador
Dentro de Lens (`kind-lens-demo`, namespace `alentapp`), mantén visibles las siguientes vistas de apoyo:
- *Workloads → Pods*
- *Workloads → Horizontal Pod Autoscalers*
- *Nodes*

> *Tip:* En el detalle de consumo de un pod de backend, ajusta el intervalo del gráfico de **1h a 5m** para apreciar mejor los picos de carga. Abre también <http://localhost:8080> en tu navegador.

### 2.6 Probar la carga de peticiones con `hey`
Para generar tráfico de prueba hacia la API y visualizar el escalado automático:

```powershell
hey -n 20 -c 2 http://localhost:3000/api/v1/socios