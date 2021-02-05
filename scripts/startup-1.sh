#! /bin/bash
set -v
export HOME=/root
CLOUDSQL_CONNECTION_NAME=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLOUDSQL_CONNECTION_NAME" -H "Metadata-Flavor: Google" )
curl -s "https://storage.googleapis.com/signals-agents/logging/google-fluentd-install.sh" | bash
service google-fluentd restart &
apt-get update
apt-get install -yq git build-essential supervisor python3-dev python3-pip libffi-dev libssl-dev mysql-client
useradd -m -d /home/pythonapp pythonapp
pip3 install --upgrade pip virtualenv
git config --global credential.helper gcloud.sh
git clone https://source.developers.google.com/p/project-bookshelf-301816/r/bookshelf-repo /opt/app
sed -i "s/DATA_BACKEND = 'datastore'/DATA_BACKEND = 'cloudsql'/g" /opt/app/7-gce/config.py
sed -i "s/PROJECT_ID = 'your-project-id'/PROJECT_ID = '$(curl "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")'/g" /opt/app/7-gce/config.py
sed -i "s/CLOUDSQL_USER = 'root'/CLOUDSQL_USER = '$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLOUDSQL_USER" -H "Metadata-Flavor: Google")'/g" /opt/app/7-gce/config.py
sed -i "s/CLOUDSQL_PASSWORD = 'your-cloudsql-password'/CLOUDSQL_PASSWORD = '$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLOUDSQL_PASSWORD" -H "Metadata-Flavor: Google")'/g" /opt/app/7-gce/config.py
sed -i "s/CLOUDSQL_DATABASE = 'bookshelf'/CLOUDSQL_DATABASE = '$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLOUDSQL_DATABASE" -H "Metadata-Flavor: Google")'/g" /opt/app/7-gce/config.py
sed -i "s/CLOUDSQL_CONNECTION_NAME = 'your-cloudsql-connection-name'/CLOUDSQL_CONNECTION_NAME = '$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLOUDSQL_CONNECTION_NAME" -H "Metadata-Flavor: Google")'/g" /opt/app/7-gce/config.py
sed -i "s/CLOUD_STORAGE_BUCKET = 'your-bucket-name'/CLOUD_STORAGE_BUCKET = '$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/CLOUD_STORAGE_BUCKET" -H "Metadata-Flavor: Google")'/g" /opt/app/7-gce/config.py
wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy && chmod +x cloud_sql_proxy
./cloud_sql_proxy -instances=$CLOUDSQL_CONNECTION_NAME=tcp:3306 &
virtualenv -p python3 /opt/app/7-gce/env 
source /opt/app/7-gce/env/bin/activate
/opt/app/7-gce/env/bin/pip install -r /opt/app/7-gce/requirements.txt
pip3 install flask flask_sqlalchemy pymysql
python3 /opt/app/7-gce/bookshelf/model_cloudsql.py
sudo chown -R pythonapp:pythonapp /opt/app
cat >/etc/supervisor/conf.d/python-app.conf << EOF
[program:pythonapp]
directory=/opt/app/7-gce
command=/opt/app/7-gce/env/bin/honcho start -f ./procfile worker bookshelf
autostart=true
autorestart=true
user=pythonapp
environment=VIRTUAL_ENV="/opt/app/7-gce/env",PATH="/opt/app/7-gce/env/bin",HOME="/home/pythonapp",USER="pythonapp"
stdout_logfile=syslog
stderr_logfile=syslog
EOF
supervisorctl reread
supervisorctl update