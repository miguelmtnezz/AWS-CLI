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