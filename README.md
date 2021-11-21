# Scripts de bash para AWS CLI

Scripts de ejemplo para experimentar con [AWS CLI][1].

Estos scripts han sido diseñados como un recurso complementario para la [práctica «AWS CLI (Command Line Interface)»][2] del módulo de [Implantación de Aplicaciones Web][3] del Ciclo Formativo de Grado Superior ASIR.

[1]: https://docs.aws.amazon.com/es_es/cli/index.html
[2]: https://josejuansanchez.org/iaw/practica-aws-cli/index.html
[3]: https://josejuansanchez.org/iaw/

# ¿Que es AWS CLI(Command Line Interface)?
La interfaz de línea de comandos (CLI) es una herramienta unificada para administrar los productos de AWS. Solo tenemos que descargar y configurar una única herramienta para poder controlar varios servicios de AWS desde la línea de comando y automatizarlo mediante secuencia de comandos.

## ¿Como funciona?

Un CLI consiste en un espacio donde se pueden escribir ordenes. El usuario teclea una orden y la ejecuta:
```
PROMPT>aws(aplicación)[parámetros]ec2 describe-instances
```
Cuando ejecutamos la orden, un módulo interpretador analiza la secuencia de caracteres recibida y, si la sintaxis es correcta, ejecuta la orden dentro del contexto del programa o sistema operativo que se encuentra.

## Primeros pasos
Amazon nos ofrece dos posibilidades de trabajar, a traves de su propio shell, o decargar en nuestra máquina local su propio interprete.

En la primera opcion no tenemos ningun problema solo hemos de ejecutar las instrucciones en su propio shell y este ejecutara la orden.

En caso de querer trabajar desde nuestra propia consola hemos de instalar su programa, en mi caso lo instalare en Windows [Instalador de AWS CLI](https://s3.amazonaws.com/aws-cli/AWSCLI64.msi).
Solo hemos de seguir los pasos del instalador y ya estaria operativo, pero para trabajar con ella hemos de configurarlo para trabajar con nuestra cuenta / laboratorio.

- La primera manera sería dirigirnos a la consola de amazon y copiar las credenciales de conexion en el fichero `credential`, almacenado en el directorio `.aws` de nuestra **Home**.
- La segunda manera es ejecutar:
  ```
  $ aws configure
  ```
  Donde añadiremos nuestra credenciales de conexion como se muestra en el siguiente ejemplo:
  ```
  aws configure
  AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
  AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
  Default region name [None]: us-west-2
  Default output format [None]: json
  ```

Una vez realizados estos pasos ya estaremos conectado a la consola de nuestra infraestructura.

---

# Ejercicios
Una vez explicado y entendido como funciona la consola de Amazon Web Service, procedo a explicar la serie de scripts creados durante esta práctica.

Esta primera parte se basa en destruir toda infraestructura previamente creada.

Y la segunda parte tratara de crear la infraestructura de manera automatizada.

## Acabar con todas las instancias `00-terminate_all_instances.sh`
```
#!/bin/bash
set -x

# Deshabilitamos la paginación de la salida de los comandos de AWS CLI
# Referencia: https://docs.aws.amazon.com/es_es/cli/latest/userguide/cliv2-migration.html#cliv2-migration-output-pager
export AWS_PAGER=""

# Eliminamos todas las intancias que están en ejecución
aws ec2 terminate-instances \
    --instance-ids $(aws ec2 describe-instances \
                    --filters "Name=instance-state-name,Values=running" \
                    --query "Reservations[*].Instances[*].InstanceId" \
                    --output text)  
```

Lo primero que realizamos en el siguiente script es desactivar la paginacion `export AWS_PAGER=''` que tiene amazon a la hora de devolver la respuesta de un comando para que nuestro script sea totalmente automatizado.

La segunda parte trata de borrar toda instancia indicandole su ID:

 `aws ec2 terminate-instances   --instance-ids (ID_ISNTANCIA)`.

Y como paso final sacamos las IDs de todas las instancia que esten corriendo:

 `aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].InstanceId" --output text` 
 
 La respuesta de este ultimo comado lo guardamos como argumento de esta manera `$()` 

## Eliminar todos los grupos de seguridad `01-delete_all_security_groups.sh`
```
#!/bin/bash
set -x

# Deshabilitamos la paginación de la salida de los comandos de AWS CLI
# Referencia: https://docs.aws.amazon.com/es_es/cli/latest/userguide/cliv2-migration.html#cliv2-migration-output-pager
export AWS_PAGER=""

# Guardamos una lista con todos los identificadores de las instancias EC2
SG_ID_LIST=$(aws ec2 describe-security-groups \
            --query "SecurityGroups[*].GroupId" \
            --output text)

# Recorremos la lista de ids y eliminamos las instancias
for ID in $SG_ID_LIST
do
    echo "Eliminando $ID ..."
    aws ec2 delete-security-group --group-id $ID
done
```
Como podemos ver el funcionamiento de este script es parecido al anterior, pero a este no podemos pasarle todas las IDs en una unica orden.

Primero hemos de obtener las IDs de los grupos de seguridad creados y su resultado lo guardamos en una variable: 

`SG_ID_LIST=$(aws ec2 describe-security-groups --query "SecurityGroups[*].GroupId" --output text)`

Este mostrará como resultado todas las IDs de los grupos de seguridad, pero como hemos comentado anteriormente hemos de ejecutar una orden por ID, asi que la solucion ha sido crear este simple bucle, al cual le pasamos cada ID de todas las almacenadas en la variable.
```
for ID in $SG_ID_LIST
do
    echo "Eliminando $ID ..."
    aws ec2 delete-security-group --group-id $ID
done
```

## Liberar todas las direcciones IP elásticas `02-delete_all_elastic_ips.sh`
```
#!/bin/bash
set -x

# Deshabilitamos la paginación de la salida de los comandos de AWS CLI
# Referencia: https://docs.aws.amazon.com/es_es/cli/latest/userguide/cliv2-migration.html#cliv2-migration-output-pager
export AWS_PAGER=""

# Obtenemos la lista de Id de las direcciones IP elásticas públicas
ELASTIC_IP_IDS=$(aws ec2 describe-addresses \
             --query Addresses[*].AllocationId \
             --output text)

# Recorremos la lista de Ids de IPs elásticas y las eliminamos
for ID in $ELASTIC_IP_IDS
do
    echo "Eliminando $ID ..."
    aws ec2 release-address --allocation-id $ID
done
```
En este script nos encontramos el mismo problema que en el anterior, hemos de liberar las direcciones IPs de forma individual, por ello pedimos a traves de la siguiente orden que nos devuelva la IDs de cada direccion IP elástica creada:

`ELASTIC_IP_IDS=$(aws ec2 describe-addresses --query Addresses[*].AllocationId --output text)`

Y una vez obtenido las IDs de las direcciones IP elástica, creamos un bucle para que ejecute la orden por cada ID.
```
for ID in $ELASTIC_IP_IDS
do
    echo "Eliminando $ID ..."
    aws ec2 release-address --allocation-id $ID
done
```

## Creación de los grupos de seguridad `03-create_security_groups.sh`

Este script es un poco largo por que en él hemos de crear el grupo de seguridad y posteriormente editar sus reglas de acceso. Recordemos de prácticas anteriores que tenemos varios servidores **FrontEnd** y **BackEnd**, por consiguiente tendremos dos grupos de seguridad a crear.

### Grupo de seguridad BackEnd
```
# Creamos el grupo de seguridad: backend-sg
aws ec2 create-security-group \
    --group-name backend-sg \
    --description "Reglas para el backend"

# Creamos una regla de accesso SSH
aws ec2 authorize-security-group-ingress \
    --group-name backend-sg \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Creamos una regla de accesso para MySQL
aws ec2 authorize-security-group-ingress \
    --group-name backend-sg \
    --protocol tcp \
    --port 3306 \
    --cidr 0.0.0.0/0

```
El primer paso es crear el grupo seguridad junto a su nombre y una breve descripcion de para que sirve:

`aws ec2 create-security-group --group-name backend-sg --description "Reglas para el backend"`

Una vez creado el grupo de seguridad hemos de añadir las reglas de conexion correspondiente a los servicios que ofrecera, en este caso se añadira el puerto 22 para poder conectarnos a la maquina de manera remota y el puerto 3306 para ofrecer el servicio MySQL:

`aws ec2 authorize-security-group-ingress --group-name backend-sg --protocol tcp --port 22 --cidr 0.0.0.0/0 `

`aws ec2 authorize-security-group-ingress --group-name backend-sg --protocol tcp --port 3306 --cidr 0.0.0.0/0 `

Como se ve lo que hacemos es indicar a que grupo de seguridad añadir las reglas, posteriormente indicamos el protocolo y puerto de conexión a utilizar y finalmente a quien vamos a permitir dicha conexión.

### Grupo de seguridad FrontEnd
```
# Creamos el grupo de seguridad: frontend-sg
aws ec2 create-security-group \
    --group-name frontend-sg \
    --description "Reglas para el frontend"

# Creamos una regla de accesso SSH
aws ec2 authorize-security-group-ingress \
    --group-name frontend-sg \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Creamos una regla de accesso HTTP
aws ec2 authorize-security-group-ingress \
    --group-name frontend-sg \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# Creamos una regla de accesso HTTPS
aws ec2 authorize-security-group-ingress \
    --group-name frontend-sg \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0
```
El metdo es el mismo que el realizado en el paso anterior pero este estara ajustado a las necesidades de nuestro servidor FrontEnd.

## Creación de las instancias `04-create_instances.sh`
```
#!/bin/bash
set -x

# Deshabilitamos la paginación de la salida de los comandos de AWS CLI
# Referencia: https://docs.aws.amazon.com/es_es/cli/latest/userguide/cliv2-migration.html#cliv2-migration-output-pager
export AWS_PAGER=""

# Variables de configuración
AMI_ID=ami-0472eef47f816e45d
COUNT=1
INSTANCE_TYPE=t2.micro
KEY_NAME=vockey

SECURITY_GROUP_FRONTEND=frontend-sg
SECURITY_GROUP_BACKEND=backend-sg

INSTANCE_NAME_LOAD_BALANCER=load-balancer
INSTANCE_NAME_FRONTEND_01=frontend-01
INSTANCE_NAME_FRONTEND_02=frontend-02
INSTANCE_NAME_BACKEND=backend

# Creamos una intancia EC2 para el balanceador de carga
aws ec2 run-instances \
    --image-id $AMI_ID \
    --count $COUNT \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP_FRONTEND \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_LOAD_BALANCER}]"

# Creamos una intancia EC2 para el frontend-01
aws ec2 run-instances \
    --image-id $AMI_ID \
    --count $COUNT \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP_FRONTEND \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_FRONTEND_01}]"

# Creamos una intancia EC2 para el frontend-02
aws ec2 run-instances \
    --image-id $AMI_ID \
    --count $COUNT \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP_FRONTEND \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_FRONTEND_02}]"

# Creamos una intancia EC2 para el backend
aws ec2 run-instances \
    --image-id $AMI_ID \
    --count $COUNT \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP_BACKEND \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_BACKEND}]" \
    --user-data sudo apt purge -y mssql* msodbc*
```

Una vez creados nuestros grupos de seguridad es momento de crear nuestras instancias. 

Como podemos observar tenemos unas variables predefinidas para poder hacer mas comodo el uso del script a cualquier usuario:

`AMI_ID`: En el indicamos el ID de la AMI a utilizar.

`COUNT`: El número de instancias a crear a traves de una única orden.

`INSTANCE_TYPE`: El tipo de arquitectura que va a utilizar nuestra máquina.

`KEY_NAME`: La clave PEM que utilizaremos para poder acceder a dichas instancias.

`SECURITY_GROUP_FRONTEND`: El nombre del grupo de seguridad que va a utlizar nuestras instancias frontend.

`SECURITY_GROUP_BACKEND`:El nombre del grupo de seguridad que va a utlizar nuestras instancias backend.

`INSTANCE_NAME_LOAD_BALANCER`: El nombre con el que queremos identificar a nuestra instancia.

`INSTANCE_NAME_FRONTEND_01`: El nombre con el que queremos identificar a nuestra instancia.

`INSTANCE_NAME_FRONTEND_02`: El nombre con el que queremos identificar a nuestra instancia.

`INSTANCE_NAME_BACKEND`: El nombre con el que queremos identificar a nuestra instancia.

La ordenes para la creacion de instancias FrontEnd y Balanceadora viene siendo la misma:
```
aws ec2 run-instances \
    --image-id $AMI_ID \
    --count $COUNT \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP_FRONTEND \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_LOAD_BALANCER}]"
```
Como vemos en el siguiente ejemplo el primer paso es indicar la orden de crear una instancia y como parámetros le indicamos la ID de la AMI a utilizar, el numero de instancias a crear en la misma orden, el tipo de arquitectura a utilizar, la clave pem para acceder a dicha instancia, el grupo de seguridad que va a utilizar y el nombre cone el cual lo identificaremos.

Y para la orden de la creacion de una instnacia BackEnd tenemos exactamente lo mismo exceptuando la ultima linea:
```
aws ec2 run-instances \
    --image-id $AMI_ID \
    --count $COUNT \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP_BACKEND \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME_BACKEND}]" \
    --user-data sudo apt purge -y mssql* msodbc*
```

El parametro `--user-data` sirve para pasar ordenes al prompt de nuestra instancia, en el que indicamos que borre todo tipo de archivo relacionado con MariaDB o MySQL.

## Creación y asociación de Dirección IP Elástica `05-create_elastic_ip.sh`
```
#!/bin/bash
set -x

# Deshabilitamos la paginación de la salida de los comandos de AWS CLI
# Referencia: https://docs.aws.amazon.com/es_es/cli/latest/userguide/cliv2-migration.html#cliv2-migration-output-pager
export AWS_PAGER=""

# Configuramos el nombre de la instancia a la que le vamos a asignar la IP elástica
INSTANCE_NAME=load-balancer

# Obtenemos el Id de la instancia a partir de su nombre
INSTANCE_ID=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=$INSTANCE_NAME" \
                      "Name=instance-state-name,Values=running" \
            --query "Reservations[*].Instances[*].InstanceId" \
            --output text)

# Creamos una IP elástica
ELASTIC_IP=$(aws ec2 allocate-address --query PublicIp --output text)

# Asociamos la IP elástica a la instancia del balanceador
aws ec2 associate-address --instance-id $INSTANCE_ID --public-ip $ELASTIC_IP
```
En este script se trata de crear una dirección IP elástica y asociar a dicha instancia.

Como podemos observar indicamos el nombre de la instancia a la que queremos darle una direccion IP fija a traves de su ID y posteriormente creamos la IP elastica y la asociamos la instancia anteriormente nombrada.

## Visualización de las instancias con su correspondiente IP `06-ip_instances.sh`
```
#!/bin/bash
set -x

# Deshabilitamos la paginación de la salida de los comandos de AWS CLI
# Referencia: https://docs.aws.amazon.com/es_es/cli/latest/userguide/cliv2-migration.html#cliv2-migration-output-pager
export AWS_PAGER=""

#Representación en forma de tabla de las IPs de cada instancia
aws ec2 describe-instances  \
--filter "Name=instance-state-name,Values=running"  \
 --query "Reservations[].Instances[].[PublicIpAddress, Tags[?Key=='Name'].Value|[0]]"  \
 --output table
```
En este caso lo que hacemos es pasar un filtro para mostrarnos unicamente aquellas instancias que estan corriendo, y posteriormente como peticion le pedimos que nos muestre la direccion IP junto al nombre que tiene asociada la instancia, cuya salida sera por forma de tabla.

---

# Referencias

- [Documentación Oficial de AWS CLI][1]
- [práctica «AWS CLI (Command Line Interface)»][2]

---
