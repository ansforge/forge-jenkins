#!/bin/bash
echo "Démarrage du script de sauvegarde de Jenkins"
#############################################################################
# Nom du script     : gitlab-backup.sh
# Auteur            : Y.ETRILLARD (QM HENIX)
# Date de Création  : 29/03/2024
# Version           : 0.0.1
# Descritpion       : Script permettant la sauvegarde des données de Jenkins
#
# Historique des mises à jour :
#-----------+--------+-------------+------------------------------------------------------
#  Version  |   Date   |   Auteur     |  Description
#-----------+--------+-------------+------------------------------------------------------
#  0.0.1    | 29/03/24 | Y.ETRILLARD  | Initialisation du script
#-----------+--------+-------------+------------------------------------------------------
#
###############################################################################################

. /root/.bash_profile

#Namespace d'instalation Nomad à mettre à jour.
NAMESPACE="NAMESPACE"

# Configuration de base: datestamp e.g. YYYYMMDD
DATE=$(date +"%Y%m%d")

# Dossier où sauvegarder les backups
BACKUP_DIR="/var/backup/JENKINS"

# Commande NOMAD
NOMAD=$(which nomad)

#Repo PATH To BACKUP DATA in the container
REPO_PATH_DATA=/var/lib/
#Archive Name of the backup repo directory
BACKUP_REPO_FILENAME="BACKUP_DATA_JENKINS_${DATE}.tar.gz"

#Repo PATH To BACKUP DATA in the container
REPO_PATH_CONF=/etc
#Archive Name of the backup repo directory
BACKUP_CONF_FILENAME="BACKUP_DATA_JENKINS_${DATE}.tar.gz"


# Nombre de jours à garder les dossiers (seront effacés après X jours)
RETENTION=3

# ---- NE RIEN MODIFIER SOUS CETTE LIGNE ------------------------------------------
#
# Create a new directory into backup directory location for this date
mkdir -p $BACKUP_DIR/$DATE

# Backup repos
echo "Starting backup jenkins data..."

$NOMAD exec -namespace=$NAMESPACE -task forge-jenkins -job forge-jenkins tar -cOzv -C $REPO_PATH_DATA jenkins > $BACKUP_DIR/$DATE/$BACKUP_REPO_FILENAME
BACKUP_RESULT=$?
if [ $BACKUP_RESULT -gt 1 ]
then
        echo "Backup Jenkins Data failed with error code : ${BACKUP_RESULT}"
        exit 1
else
        echo "Backup Jenkins Data done"
fi

# Remove files older than X days
find $BACKUP_DIR/* -mtime +$RETENTION -exec rm -rf {} \;

echo "Backup Jenkins finished"

