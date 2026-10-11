
02 demo romper · SH
#!/usr/bin/env bash
# Acto de P3: autorrecuperación y estado deseado.
# Correr cada bloque a mano durante la demo (no todo junto), con Lens abierto
# en Workloads > Pods, filtrado por namespace "alentapp".
set -euo pipefail
 
echo "== 1) Simular una caída =="
echo "Opción A) matar el proceso DESDE ADENTRO del contenedor: mismo pod se reinicia in situ."
echo "Opción B) borrar el pod DESDE AFUERA: el Deployment crea uno nuevo con otro nombre."
kubectl get pods -n alentapp -l app=backend
read -p "Elegí A o B: " OPCION
POD=$(kubectl get pods -n alentapp -l app=backend -o jsonpath='{.items[0].metadata.name}')
if [ "$OPCION" = "A" ] || [ "$OPCION" = "a" ]; then
  echo "Matando el proceso principal (PID 1) dentro de $POD..."
  kubectl exec -n alentapp "$POD" -- kill 1
else
  echo "Borrando el pod $POD..."
  kubectl delete pod "$POD" -n alentapp
fi
 
echo
echo "== 2) Drenar un nodo completo =="
echo "Mostrar en Lens -> Nodes: el nodo queda Unschedulable y sus pods se reprograman en el otro worker."
kubectl get nodes
read -p "Pegá el nombre del nodo a drenar (ej: lens-demo-worker2) y Enter: " NODO
kubectl cordon "$NODO"
kubectl drain "$NODO" --ignore-daemonsets --delete-emptydir-data
 
echo
echo "== 3) Restaurar el nodo (hacer SIEMPRE antes de terminar la demo) =="
read -p "Enter para hacer uncordon de $NODO..." _
kubectl uncordon "$NODO"
echo "Nodo $NODO restaurado."
 
