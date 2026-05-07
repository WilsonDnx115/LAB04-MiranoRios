# AWS + Lambda Integration

## Estructura del proyecto

```text
LAB04/
├── iac/                        # Infraestructura como Código (Terraform)
│   ├── apigateway.tf           # Configuración de HTTP API y rutas
│   ├── dlq.tf                  # Cola de mensajes fallidos (Dead Letter Queue)
│   ├── iam.tf                  # Roles y políticas de permisos AWS
│   ├── igw.tf                  # Internet Gateway
│   ├── lambda_crop.tf          # Definición de la Lambda de procesamiento
│   ├── lambda_upload.tf        # Definición de la Lambda de subida
│   ├── nat.tf                  # NAT Gateways para salida a internet
│   ├── outputs.tf              # Variables de salida (URLs y nombres)
│   ├── providers.tf            # Configuración de proveedores (AWS)
│   ├── s3.tf                   # Buckets y notificaciones de S3
│   ├── sg.tf                   # Grupos de seguridad (Firewall)
│   ├── sqs.tf                  # Cola principal de mensajería
│   ├── subnets.tf              # Redes públicas y privadas
│   ├── terraform.tfvars        # Valores de las variables
│   ├── variables.tf            # Definición de variables
│   ├── vpc.tf                  # Red principal (VPC)
│   └── vpc_endpoint.tf         # Conexiones privadas (S3/SQS)
├── src/                        # Código fuente de las aplicaciones
│   └── lambdas/
│       ├── crop/
│       │   ├── index.mjs       # Lógica de recorte de imagen (Sharp)
│       │   └── package.json    # Dependencias (sharp)
│       └── upload/
│           ├── index.mjs       # Lógica de subida a S3
│           └── package.json    # Dependencias (busboy, uuid)
├
└── README.md                   # Documentación del proyecto
```

## Herramientas
* **Terraform**: Para desplegar la infraestructura como código (IaC).
* **AWS CLI**: Para gestionar los servicios de AWS y configurar la sesión del usuario.

### Servicios AWS Utilizados
* **API Gateway HTTP API v2**: Actúa como punto de entrada (`POST /upload` vía HTTPS, TLS 1.2+) con Payload format 2.0 y CORS habilitado. Cuenta con un límite de Throttling de 10,000 rps y envía logs de acceso en formato JSON a CloudWatch.

* **AWS Lambda**: Ejecuta la lógica de negocio sin administrar servidores distribuyendo ENIs automáticamente en dos AZs.
  * `upload-lambda` (256 MB, 30s timeout): Recibe peticiones `multipart/form-data` o `JSON+base64` de hasta 10 MB. Utiliza `busboy` y `uuid` para subir la imagen a S3.

  * `crop-lambda` (512 MB, 60s timeout): Activada por SQS, utiliza `sharp 0.33` para redimensionar (40x40 cover) y aplicar una máscara circular SVG, guardando el resultado como PNG transparente.

* **Amazon S3**: Almacenamiento completamente privado con encriptación AES-256 (SSE).
  * `uploads/`: Guarda imágenes originales (jpg, png, gif, webp) con expiración de 30 días. Al crearse un objeto (ObjectCreated), dispara una notificación a SQS a través de la red interna de AWS.
  * `processed/`: Guarda las imágenes finales recortadas con expiración de 90 días.

* **Amazon SQS**: Cola de mensajes estándar que asegura el desacoplamiento.
  * `Main Queue`: Tiene un visibility timeout de 360s, long polling de 20s y un máximo de 3 reintentos
  * `Dead-Letter Queue (DLQ)`: Retiene mensajes fallidos por 14 días y activa una alarma de CloudWatch en caso de haber mensajes visibles.

* **Amazon VPC**: Entorno de red privada (CIDR 10.0.0.0/16) con subredes en múltiples Zonas de Disponibilidad (AZ-a, AZ-b) y NAT Gateways para alta disponibilidad. Utiliza 

**VPC Endpoints** S3 Gateway y SQS Interface con Private DNS para asegurar que el tráfico permanezca en la red troncal de AWS sin salir al internet público.

## Despliegue

### Procedimiento para Loguearte

Colocar en cmd o PowerShell el siguiente comando:

```
aws configure sso
```
Colocas tu nombre de sesión, start url, región y saltas lo de registration scopes.

```
aws configure sso --use-device-code
```
Entras al vínculo con la cuenta que deseas acceder, ingresas el código, eliges el rol a usar, colocas la región, seleccionas `json` como formato y colocas el profile name.

### Procedimiento Terraform

#### ESPACIOS DE TRABAJO EN TF

CREAR ENTORNO DE TRABAJO: Puedes colocar el nombre que desees, para este caso sería la creación de 3 espacios de trabajo, DEV, QA, PROD

```
terraform workspace new DEV  
```

SELECCIONAR 

```
terraform workspace select QA
```

PARA VER MÁS COMANDOS

```
terraform workspace  
```

#### Preparación

Crear un archivo `.tfvars` dentro del directorio `iac/`. Debe contener:

```
aws_region = "region_name" # región a trabajar
project_name = "generic_name" # nombre que se desea dar a ciertos recursos 
```

Aplicar el siguiente comando para iniciar:

```
terraform init
```

Aplicar el siguiente comando para verificar los recursos que serán creados y si no se presenta un error:

```
terraform plan
```

Aplicar el siguiente comando para inicializar los recursos en la nube en la cuenta seleccionada:

```
terraform apply
```

Aplicar el siguiente comando para eliminar todos los recursos privados al culminar lo que se desea realizar con el proyecto, para evitar costes grandes no deseados:

```
terraform destroy
```

## Pruebas de Funcionamiento

* **Vía Consola S3**: Sube manualmente una imagen a la carpeta `uploads/` del bucket y verifica que en segundos aparezca la versión procesada en la carpeta `processed/`.

