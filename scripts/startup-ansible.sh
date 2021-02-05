#! /bin/bash
set -v
apt-get update
apt-get install git -y
apt-get install ansible -y
git config --global credential.helper gcloud.sh
git clone https://source.developers.google.com/p/project-bookshelf-301816/r/bookshelf-repo /opt/app
#
sed -i "s/DATA_BACKEND = 'datastore'/DATA_BACKEND = 'cloudsql'/g" /opt/app/7-gce/config.py
sed -i "s/PROJECT_ID = 'your-project-id'/PROJECT_ID = '$(curl "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")'/g" /opt/app/7-gce/config.py
sed -i "s/CLOUDSQL_USER = 'root'/CLOUDSQL_USER = '$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLOUDSQL_USER" -H "Metadata-Flavor: Google")'/g" /opt/app/7-gce/config.py
sed -i "s/CLOUDSQL_PASSWORD = 'your-cloudsql-password'/CLOUDSQL_PASSWORD = '$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLOUDSQL_PASSWORD" -H "Metadata-Flavor: Google")'/g" /opt/app/7-gce/config.py
sed -i "s/CLOUDSQL_DATABASE = 'bookshelf'/CLOUDSQL_DATABASE = '$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLOUDSQL_DATABASE" -H "Metadata-Flavor: Google")'/g" /opt/app/7-gce/config.py
sed -i "s/CLOUDSQL_CONNECTION_NAME = 'your-cloudsql-connection-name'/CLOUDSQL_CONNECTION_NAME = '$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLOUDSQL_CONNECTION_NAME" -H "Metadata-Flavor: Google")'/g" /opt/app/7-gce/config.py
sed -i "s/CLOUD_STORAGE_BUCKET = 'your-bucket-name'/CLOUD_STORAGE_BUCKET = '$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLOUD_STORAGE_BUCKET" -H "Metadata-Flavor: Google")'/g" /opt/app/7-gce/config.py
sed -i "s/cloudsql_connection_name:/cloudsql_connection_name: $(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLOUDSQL_CONNECTION_NAME" -H "Metadata-Flavor: Google")/g" /opt/app/ansible/env_vars
#
ansible-playbook /opt/app/ansible/playbook_bookshelf_webapp.yml