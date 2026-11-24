# Ensayo de la clase del 25 de noviembre de 2026

GitHub Actions publicó dos imágenes en ECR con credenciales temporales OIDC y desplegó ambas por digest en ECS/Fargate. En cada despliegue verificamos el digest del contenedor en ejecución, la versión de `/health`, una clasificación válida y el rechazo de una entrada vacía con 422. La prueba de regresión repitió la misma consulta de prioridad baja antes y después del rollback.

| Versión | Hora de Madrid | Definición de tarea ECS | Salud | Consulta de prioridad baja | GitHub Actions |
|---|---|---|---:|---:|---|
| A inicial | 24/11 23:50:10 | `s18-aula-20261125:3` | 200 | 200 | [Ejecución](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/actions/runs/45504113148) |
| B con regresión | 24/11 23:58:20 | `s18-aula-20261125:4` | 200 | 500 | [Ejecución](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/actions/runs/45504644172) |
| A recuperada | 25/11 00:02:00 | `s18-aula-20261125:5` | 200 | 200 | [Ejecución](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/actions/runs/45505831395) |

| Imagen | Commit publicado | Digest exacto en ECR |
|---|---|---|
| [A](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/actions/runs/45503830785) | `783f342613995a6de8310c01eb435baafbf27011` | `sha256:37573b132763fc2ea3a298a905d33faeba0104a7f662b34e4a8a3b9514ff205e` |
| [B](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/actions/runs/45504080834) | `d28008cf95845a8c4e85d6bbf71e3b29a244a666` | `sha256:e706939f341abafcaafe72ae748c44cd3f165933201aa4608bc78e7c42c72391` |

## Fallo y recuperación

La consulta «Tengo una duda sobre los horarios» llegó a B con prioridad baja. CloudWatch enlazó el 500 con una excepción `KeyError` mediante el request ID `0d2b1d4f-3027-43f8-84b4-ccecf113fc2b`. En ese minuto, el panel registró **1 respuesta 5xx** y **3,49 ms de latencia p95**. La alarma de errores 5xx entró en ALARM. El smoke de prioridad media había pasado en esa misma versión.

El rollback utilizó el digest original de A y registró una nueva revisión de la tarea. La consulta de prioridad baja volvió a responder 200. CloudWatch confirmó el commit de A y el request ID `78f6bf31-7903-4bbb-8fc1-32ffd98ac8c6`.

## Qué impidió un despliegue incorrecto

- La [PR defectuosa](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/pull/1) quedó bloqueada con dos tests en rojo. La [PR de la versión B](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/pull/2) pasó los controles previos.
- GitHub [rechazó un dispatch desde otra rama](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/actions/runs/45503922131) antes de ejecutar los pasos del job. El [diagnóstico del entorno](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/actions/runs/45503817597) mostró la audiencia de STS y el subject exacto de `staging`. Los roles de publicar y desplegar tienen confianzas distintas.
- La [PR de solución](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/pull/3) muestra la [prueba que faltaba, en rojo](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/actions/runs/45504149754), y [el arreglo, en verde](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/actions/runs/45504229664). La rama de la solución se conserva para estudiar el cambio.

Para repetir el ejercicio desde cero, usa el código A de la rama principal. El commit de preparación de la rama principal puede tener otra imagen en ECR. La publicación por sí sola no cambia staging. Las etiquetas [aula-A](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/tree/aula-A) y [aula-B](https://github.com/JoseAntonioNuevo/thepower-cicd-aws/tree/aula-B) identifican las revisiones de la aplicación que se desplegaron en este ensayo.
