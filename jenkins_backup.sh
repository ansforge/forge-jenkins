#!/bin/bash
echo "Démarrage du script de sauvegarde de Jenkins"
#############################################################################
# Nom du script     : jenkins-backup.sh
# Auteur            : Y.ETRILLARD (QM HENIX)
# Date de Création  : 29/03/2024
# Version           : 1.0.0
# Descritpion       : Script permettant la sauvegarde des données de Jenkins
#
# Historique des mises à jour :
#-----------+--------+-------------+------------------------------------------------------
#  Version  |   Date   |   Auteur     |  Description
#-----------+--------+-------------+------------------------------------------------------
#  0.0.1    | 29/03/24 | Y.ETRILLARD  | Initialisation du script
#-----------+--------+-------------+------------------------------------------------------
#  1.0.0    | 28/08/24 | M. FAUREL   | Modification de la casse du path et timestamp
#-----------+--------+-------------+------------------------------------------------------
#
###############################################################################################

. /root/.bash_profile

#Namespace d'instalation Nomad à mettre à jour.
NAMESPACE="NAMESPACE"

# Configuration de base: datestamp e.g. YYYYMMDD
DATE=$(date +"%Y%m%d")
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Dossier où sauvegarder les backups
BACKUP_DIR="/var/backup/jenkins"

# Commande NOMAD
NOMAD=$(which nomad)

#Repo PATH To BACKUP DATA in the container
REPO_PATH_DATA=/var/lib/
#Archive Name of the backup repo directory
BACKUP_REPO_FILENAME="backup_data_jenkins_${DATE}.tar.gz"

#Repo PATH To BACKUP DATA in the container
REPO_PATH_CONF=/etc
#Archive Name of the backup repo directory
BACKUP_CONF_FILENAME="backup_conf_jenkins_${DATE}.tar.gz"


# Nombre de jours à garder les dossiers (seront effacés après X jours)
RETENTION=10

# ---- NE RIEN MODIFIER SOUS CETTE LIGNE ------------------------------------------
#
# Create a new directory into backup directory location for this date
mkdir -p $BACKUP_DIR/$DATE

# Backup repos
echo "${TIMESTAMP} Starting backup jenkins data..."

# Remove -namespace=$NAMESPACE 
$NOMAD exec -task forge-jenkins -job forge-jenkins tar -cOzv -C $REPO_PATH_DATA jenkins > $BACKUP_DIR/$DATE/$BACKUP_REPO_FILENAME
BACKUP_RESULT=$?
if [ $BACKUP_RESULT -gt 1 ]
then
       echo "${TIMESTAMP} Backup Jenkins Data failed with error code : ${BACKUP_RESULT}"
        exit 1
else
        echo "${TIMESTAMP} Backup Jenkins Data done"
fi

# Backup conf
echo "${TIMESTAMP} Starting backup gitlab conf..."

# Remove -namespace=$NAMESPACE 
$NOMAD exec -task forge-jenkins -job forge-jenkins tar  -cOzv -C $REPO_PATH_CONF jenkins > $BACKUP_DIR/$DATE/$BACKUP_CONF_FILENAME
BACKUP_RESULT=$?
if [ $BACKUP_RESULT -gt 1 ]
then
        echo "${TIMESTAMP} Backup Jenkins Conf failed with error code : ${BACKUP_RESULT}"
        exit 1
else
        echo "${TIMESTAMP} Backup Jenkins Conf done"
fi

# Remove files older than X days
find $BACKUP_DIR/* -mtime +$RETENTION -exec rm -rf {} \;

echo "Backup Jenkins finished"

