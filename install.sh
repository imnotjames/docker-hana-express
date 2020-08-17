#!/bin/bash
set -e

PLATFORM="LINUX_X86_64"
PLATFORM_DPA="LIN_X86_64"
HDB_SERVER_COMP_DIR="HDB_SERVER_${PLATFORM}"
HDB_LCM_COMP_DIR="HDB_LCM_${PLATFORM}"
HOST_NAME="localhost"
SID="HXE"
HXE_ADM_USER="hxeadm"
INSTANCE="90"

# Install Hana

MASTER_PASSWORD_XML=$(
cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Passwords>
  <password><![CDATA[${MASTER_PASSWORD}]]></password>
  <system_user_password><![CDATA[${MASTER_PASSWORD}]]></system_user_password>
  <sapadm_password><![CDATA[${MASTER_PASSWORD}]]></sapadm_password>
  <xs_master_password><![CDATA[${MASTER_PASSWORD}]]></xs_master_password>
  <org_manager_password><![CDATA[${MASTER_PASSWORD}]]></org_manager_password>
  <master_password><![CDATA[${MASTER_PASSWORD}]]></master_password>
</Passwords>
EOF
)

echo "Installing HDB server..."
/tmp/hxe/HANA_EXPRESS_20/DATA_UNITS/${HDB_LCM_COMP_DIR}/hdblcm \
  --action=install \
  --sid="${SID}" \
  --number="${INSTANCE}" \
  --hostname="${HOST_NAME}" \
  --home="/hana/home/" \
  --components="server" \
  --component_root="/tmp/hxe/HANA_EXPRESS_20/DATA_UNITS" \
  --hdbinst_server_import_content=off \
  --read_password_from_stdin=xml \
  --create_initial_tenant=off \
  --skip_hostagent_calls \
  --skip_modify_sudoers \
  --system_usage=development \
  --auto_initialize_services=off \
  --nostart \
  --hdbinst_server_import_content=off \
  --hdbinst_plugin_nostart \
  --hdbinst_plugin_no_scriptserver_restart \
  --batch \
  <<< "${MASTER_PASSWORD_XML}"

if [ $? -ne 0 ]; then
echo
  echo "Failed to install HDB server."
  exit 1
fi

ls /hana/home

chmod 755 /hana/home/.profile
sed -i "s|^if \[ -f \$HOME/\.bashrc.*|if \[ -f \$HOME/\.bashrc -a -z \"\$SAPSYSTEMNAME\" \]; then|" /hana/home/.profile

echo "mkdir -p /hana/home/bin" | su -l ${HXE_ADM_USER}

# Copy change_key.sh to <hxeadm home>/bin directory
echo "cp -p /tmp/hxe/HANA_EXPRESS_20/change_key.sh /hana/home/bin" | su -l ${HXE_ADM_USER}
echo "chmod 755 /hana/home/bin/change_key.sh" | su -l ${HXE_ADM_USER}

# Copy hxe_gc.sh to <hxeadm home>/bin directory
echo "cp -p /tmp/hxe/HANA_EXPRESS_20/hxe_gc.sh /hana/home/bin" | su -l ${HXE_ADM_USER}
echo "chmod 755 /hana/home/bin/hxe_gc.sh" | su -l ${HXE_ADM_USER}

# Cleanup Installation Materials

rm -rf rm /tmp/.sap* /tmp/hxe.tgz /tmp/hxe/ /var/tmp/*

# The rest of this is removing features we _probably_ don't need to make the image smaller.

# Cleanup unused documentation files
rm -rf /hana/shared/HXE/hdblcm/resources/*

# Cleanup language grouper codes
rm -rf /hana/shared/HXE/global/hdb/custom/config/lexicon/lang/*

# Remove setup code we won't be using again
rm -rf /hana/shared/HXE/global/hdb/saphostagent_setup/

# Remove probably unused auto_content
rm -rf /hana/shared/HXE/global/hdb/auto_content/*.tgz
