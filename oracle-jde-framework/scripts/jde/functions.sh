#!/bin/bash

# This script contains utility functions for the EBS project

#Source Env
# if [ -f ~/scripts/environment ]; then
#     source /home/oracle/scripts/environment
# else     
#     source /scripts/environment
# fi

log_path=~/logs
if [ ! -d "$log_path" ]; then  mkdir -p "$log_path"; fi
if [ -z "$BUCKET" ]; then BUCKET=$(gcloud storage ls | grep oracle-jde-toolkit-storage-bucket); fi

# paths
local_media=/u02

# Variables:
db_sys_password="Manager123"
web_wls_password="AdminPassword123"

## function list | Common
is_root_user() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0  # true, user is root
    else
        echo "User is not root"
        return 1  # false, user is not root
    fi
}

is_oracle_user() {
    if [ "$(id -un)" = "oracle" ]; then
        return 0  # true, user is oracle
    else
        echo "User is not oracle"
        return 1  # false, user is not oracle
    fi
}

is_opc_user() {
    if [ "$(id -un)" = "opc" ]; then
        return 0  # true, user is opc
    else
        echo "User is not opc"
        return 1  # false, user is not opc
    fi
}

print_task(){
    echo -e "\n\033[1m### ${1} \033[0m"    
}

copy_file_as_opc() {
    opc_key_path=/home/opc/.ssh/jde_oneclick_key  
    target_server=${1}
    target_user=${2}
    source_path=${3}
    remote_path=${4}
    
    # archive_name="p39034528_190000_Linux-x86-64.zip"
    # source_path="${local_media}/${archive_name}"
    # remote_path="/u01/${archive_name}"

    if ! sudo -u opc test -r "$source_path"; then
      echo "Source file is not readable by opc: $source_path"
      return 1
    fi

    echo " -> Copying ${source_path} as opc and staging it as ${target_user}@${target_server}:${remote_path}"
    sudo -u opc cat "$source_path" | sudo -u opc ssh -T -i "$opc_key_path"  -o StrictHostKeyChecking=accept-new -o BatchMode=yes \
      "opc@${target_server}" "sudo -u '${target_user}' tee '${remote_path}' >/dev/null"

}

execute_as_opc() {
    opc_key_path=/home/opc/.ssh/jde_oneclick_key  
    target_server=${1}
    target_user=${2}
    command=${3}

    echo " -> Executing command on ${target_user}@${target_server} -> ${command}"
    sudo -u opc ssh -T -i "$opc_key_path"  -o StrictHostKeyChecking=accept-new -o BatchMode=yes \
      "opc@${target_server}" "sudo -u '${target_user}' ${command}"
}

execute_as_root() {
    opc_key_path=/home/opc/.ssh/jde_oneclick_key  
    target_server=${1}
    command=${2}

    echo " -> Executing command on ${target_user}@${target_server} -> ${command}"
    sudo -u opc ssh -T -i "$opc_key_path"  -o StrictHostKeyChecking=accept-new -o BatchMode=yes \
      "opc@${target_server}" "sudo ${command}"
}

## Example Funciton
function_example() {
 logfile=${log_path}/$(date +%Y%m%d_%H%M%S)_${FUNCNAME[0]}.log
 {
    date
    echo -e "\n\033[1m
         =========================================================================
         JD Edwards EntOne ON GCP TOOLKIT FUNCTION: ${FUNCNAME[0]}
         =========================================================================
         Function precreates dirs, files, ownership and other root activites
         ------------------------------------------------------------------------- \033[0m"
    
    # Check if called by root
    if ! is_oracle_user; then echo "This function must be run as oracle."; return 1; fi
    # Check if OS is ready
    
    ### actual function betweens these comments
    print_task "Doing Stuff - function "


    ### EOF actual function betweens these comments
    echo -e "\nlog: $logfile"
    date              
 } 2>&1 | tee -a ${logfile}
}


## COMMON FUCNTIONS
create_and_dist_opc_key() {
 logfile=${log_path}/$(date +%Y%m%d_%H%M%S)_${FUNCNAME[0]}.log
 {
    date
    echo -e "\n\033[1m
         =========================================================================
          JD Edwards EntOne ON GCP TOOLKIT FUNCTION: ${FUNCNAME[0]}
         =========================================================================
         Creates and distributes opc key to opc users accross the nodes
         ------------------------------------------------------------------------- \033[0m"
    
    # Check if called by root
    #if ! is_oracle_user; then echo "This function must be run as oracle."; return 1; fi
    # Check if OS is ready
    
    ### actual function betweens these comments
    print_task "Creating an OPC ssh key"
    sudo -u opc bash -c 'mkdir -p ~/.ssh && [ -f ~/.ssh/jde_oneclick_key ] || ssh-keygen -t rsa -b 4096 -m PEM -N "" -f ~/.ssh/jde_oneclick_key -C "jde_oneclick"'
    
    print_task "Listing OPC ssh key's"
    sudo -u opc bash -c 'ls -l ~/.ssh'

    # get list of vm's
    #zone=$(gcloud compute instances list --filter="$(hostname)" --format="value(zone.basename())")
    #vm_list=$(gcloud compute instances list \
    #--filter="labels.application=oracle-jde-vision AND disks.licenses:oracle-linux" \
    #--format="value(name)")
    
    ## distributing OPC public key to all opc users on the nodes


    PUB_KEY=$(sudo -u opc cat /home/opc/.ssh/jde_oneclick_key.pub)

    gcloud compute instances list \
  --filter="labels.application=oracle-jde-vision AND disks.licenses:oracle-linux" \
  --format="value(name, zone.basename())" | while read -r name zone; do

    print_task "Distributing opc public key to: $name ($zone)" 

    gcloud compute ssh "$name" --zone="$zone" --quiet --verbosity=error \
      --ssh-flag="-o StrictHostKeyChecking=accept-new" \
      --command="sudo -u opc bash -c '
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        
        # Check if authorized_keys exists AND already contains the public key
        if [ -f ~/.ssh/authorized_keys ] && grep -qF \"$PUB_KEY\" ~/.ssh/authorized_keys; then
          echo \"[SKIP] Key already exists in authorized_keys.\"
        else
          echo \"[ADD] Appending public key to authorized_keys.\"
          echo \"$PUB_KEY\" >> ~/.ssh/authorized_keys
          chmod 600 ~/.ssh/authorized_keys
        fi
      '" < /dev/null

done

    ### TESTING connectiivty 
    GREEN_BOLD="\033[1;32m"
    RED_BOLD="\033[1;31m"
    NC="\033[0m" # Reset formatting
    gcloud compute instances list \
  --filter="labels.application=oracle-jde-vision AND disks.licenses:oracle-linux" \
  --format="value(name)" | while read -r vm; do

    print_task "Testing SSH connection: user opc@$(hostname) to opc@$vm using key /home/opc/.ssh/jde_oneclick_key"
    echo "command:  ssh -n -i /home/opc/.ssh/jde_oneclick_key -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=5 opc@$vm"

    if sudo -u opc ssh -n -i /home/opc/.ssh/jde_oneclick_key \
      -o StrictHostKeyChecking=accept-new \
      -o BatchMode=yes \
      -o ConnectTimeout=5 \
      opc@"$vm" "hostname" >/dev/null 2>&1; then
        echo -e "${GREEN_BOLD}[OK] $vm -  Connected ${NC}"
    else
        echo -e "${RED_BOLD}[FAILED] Connection error STOP HERE and investigate ${NC}"
    fi

done


    ### EOF actual function betweens these comments
    echo -e "\nlog: $logfile"
    date              
 } 2>&1 | tee -a ${logfile}
}

stage_jde_software() {
 logfile=${log_path}/$(date +%Y%m%d_%H%M%S)_${FUNCNAME[0]}.log
 {
    date
    echo -e "\n\033[1m
         =========================================================================
         JD Edwards EntOne ON GCP TOOLKIT FUNCTION: ${FUNCNAME[0]}
         =========================================================================
         Function to stage JDE software from GCP bucke to local FS
         ------------------------------------------------------------------------- \033[0m"
    
    
    ### actual function betweens these comments
    print_task "Local software path: $local_media"
    print_task "GCP bucket: ${BUCKET}"
    print_task "List of bucket contents:"
    gcloud storage ls ${BUCKET}

    print_task "Staging Provisioning server:"
    sudo gcloud  storage cp -r ${BUCKET}* $local_media
    sudo chown -Rf root:oracle /u02

    # note - districuting using OPC user with transparent ssh

    print_task "Staging Database server:"
    # use copy funct server user source_file dest_file
    copy_file_as_opc jde-demo-db oracle /u02/LINUX.X64_193000_db_home.zip /u01/LINUX.X64_193000_db_home.zip
    copy_file_as_opc jde-demo-db oracle /u02/p6880880_190000_Linux-x86-64.zip /u01/p6880880_190000_Linux-x86-64.zip
    copy_file_as_opc jde-demo-db oracle /u02/p39034528_190000_Linux-x86-64.zip /u01/p39034528_190000_Linux-x86-64.zip

    print_task "Staging Weblogic server:"
    #copy_file_as_opc jde-demo-web oracle /u02/jdk-8u202-linux-x64.tar.gz /u01/jdk-8u202-linux-x64.tar.gz
    copy_file_as_opc jde-demo-web oracle /u02/V994956-01.zip /u01/V994956-01.zip
    copy_file_as_opc jde-demo-web oracle /u02/p28186730_1394224_Generic.zip /u01/p28186730_1394224_Generic.zip
    copy_file_as_opc jde-demo-web oracle /u02/p39796866_141100_Generic.zip /u01/p39796866_141100_Generic.zip


    ### EOF actual function betweens these comments
    echo -e "\nlog: $logfile"
    date              
 } 2>&1 | tee -a ${logfile}
}

start_jde_provisioning_server() {
 logfile=${log_path}/$(date +%Y%m%d_%H%M%S)_${FUNCNAME[0]}.log
 {
    date
    echo -e "\n\033[1m
         =========================================================================
         JD Edwards EntOne ON GCP TOOLKIT FUNCTION: ${FUNCNAME[0]}
         =========================================================================
         Function to stage and start provisioning server
         ------------------------------------------------------------------------- \033[0m"

    if [ "$(sudo systemctl show -p LoadState --value E1CloudConsole.service)" = "loaded" ]; then
    print_task "Provisioning Server has been enabled and is running"
    sudo systemctl status E1CloudConsole.service

    return 0
    fi
    
    ### actual function betweens these comments
    print_task "Unarachive Software on Provisioning server:"
    sudo find /u02/ -type f -name 'V105*.zip' -exec sudo unzip -q -o {} -d /u01 \;
    sudo ls -l /u01

    print_task "Building Provisioning server:"
    sudo sh -c 'cd /u01 && sh rebuild.sh'

    print_task "Starting Provisioning server:"
    sudo /u01/setupPr.sh

    print_task "Wait ~ 3mins to provision server to spinup - connect to IAP tunnel to access the provisioning server port 3000 and 8998"
    print_task "gcloud compute ssh jde-demo-prov --tunnel-through-iap -- -L 3000:localhost:3000 -L 8998:localhost:8998"

    sleep 60 
    print_task "Status of E1CloudConsole.service:"
    sudo systemctl status E1CloudConsole.service

    ### EOF actual function betweens these comments
    echo -e "\nlog: $logfile"
    date              
 } 2>&1 | tee -a ${logfile}
}


stage_oracle_database() {
 logfile=${log_path}/$(date +%Y%m%d_%H%M%S)_${FUNCNAME[0]}.log
 {
    date
    echo -e "\n\033[1m
         =========================================================================
         JD Edwards EntOne ON GCP TOOLKIT FUNCTION: ${FUNCNAME[0]}
         =========================================================================
         Function to provision Oracle Database for the JDE
         ------------------------------------------------------------------------- \033[0m"

    stat=$(execute_as_opc jde-demo-db oracle "ps -fea | grep pmon " | grep pmon_ORCL | wc -l)

    if [ "$stat" == "1" ]; then
    print_task "Database Server has setup and is running"
    echo "proceed to next step"
    return 0
    fi

    print_task "Staging RDBMS Software on Database server:"
    execute_as_opc jde-demo-db oracle "mkdir -p /u01/app/oracle/product/19.0.0/db_1 /u01/app/oraInventory /u01/oradata"
    execute_as_root jde-demo-db "echo -e 'inventory_loc=/u01/app/oraInventory\ninst_group=dba' | sudo tee /etc/oraInst.loc"
    execute_as_opc jde-demo-db oracle "unzip -qo /u01/LINUX.X64_193000_db_home.zip -d /u01/app/oracle/product/19.0.0/db_1"
    execute_as_opc jde-demo-db oracle "mv /u01/app/oracle/product/19.0.0/db_1/OPatch/ /u01/app/oracle/product/19.0.0/db_1/OPatch.12.2.0.1.17"
    execute_as_opc jde-demo-db oracle "unzip -qo /u01/p6880880_190000_Linux-x86-64.zip -d /u01/app/oracle/product/19.0.0/db_1"
    execute_as_opc jde-demo-db oracle "unzip -qo /u01/p39034528_190000_Linux-x86-64.zip -d /u01"
    execute_as_opc jde-demo-db oracle "sed -i 's/OL7/OL8/g' /home/oracle/.bash_profile"
    execute_as_opc jde-demo-db oracle "/u01/app/oracle/product/19.0.0/db_1/runInstaller -silent -applyRU /u01/39034528"
    execute_as_opc jde-demo-db oracle "/u01/app/oracle/product/19.0.0/db_1/OPatch/opatch lspatches"

     print_task "Installing RDBMS Software on Database server:"

     execute_as_opc jde-demo-db oracle "echo  'oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.0.0
oracle.install.option=INSTALL_DB_SWONLY
UNIX_GROUP_NAME=dba
INVENTORY_LOCATION=/u01/app/oraInventoryDB
ORACLE_HOME=/u01/app/oracle/product/19.0.0/db_1
ORACLE_BASE=/u01/app/oracle
oracle.install.db.InstallEdition=EE
oracle.install.db.OSDBA_GROUP=dba
oracle.install.db.OSOPER_GROUP=dba
oracle.install.db.OSBACKUPDBA_GROUP=dba
oracle.install.db.OSDGDBA_GROUP=dba
oracle.install.db.OSKMDBA_GROUP=dba
oracle.install.db.OSRACDBA_GROUP=dba
oracle.install.db.rootconfig.executeRootScript=false
oracle.install.db.rootconfig.configMethod=
oracle.install.db.rootconfig.sudoPath=
oracle.install.db.rootconfig.sudoUserName=
oracle.install.db.CLUSTER_NODES=
oracle.install.db.config.starterdb.type=
oracle.install.db.config.starterdb.globalDBName=
oracle.install.db.config.starterdb.SID=
oracle.install.db.ConfigureAsContainerDB=
oracle.install.db.config.PDBName=
oracle.install.db.config.starterdb.characterSet=
oracle.install.db.config.starterdb.memoryOption=
oracle.install.db.config.starterdb.memoryLimit=
oracle.install.db.config.starterdb.installExampleSchemas=
oracle.install.db.config.starterdb.password.ALL=
oracle.install.db.config.starterdb.password.SYS=
oracle.install.db.config.starterdb.password.SYSTEM=
oracle.install.db.config.starterdb.password.DBSNMP=
oracle.install.db.config.starterdb.password.PDBADMIN=
oracle.install.db.config.starterdb.managementOption=
oracle.install.db.config.starterdb.omsHost=
oracle.install.db.config.starterdb.omsPort=
oracle.install.db.config.starterdb.emAdminUser=
oracle.install.db.config.starterdb.emAdminPassword=
oracle.install.db.config.starterdb.enableRecovery=
oracle.install.db.config.starterdb.storageType=
oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=
oracle.install.db.config.starterdb.fileSystemStorage.recoveryLocation=
oracle.install.db.config.asm.diskGroup=
oracle.install.db.config.asm.ASMSNMPPassword=
' > /tmp/db_install.rsp"
execute_as_opc jde-demo-db oracle "cp /tmp/db_install.rsp /u01"
execute_as_opc jde-demo-db oracle "sh -c 'export CV_ASSUME_DISTID=OL8; exec /u01/app/oracle/product/19.0.0/db_1/runInstaller -executePrereqs -silent -responseFile /u01/db_install.rsp'"
execute_as_opc jde-demo-db oracle "sh -c 'export CV_ASSUME_DISTID=OL8; exec /u01/app/oracle/product/19.0.0/db_1/runInstaller -silent -responseFile /u01/db_install.rsp'"
execute_as_root jde-demo-db "/u01/app/oracle/product/19.0.0/db_1/root.sh"


    print_task "Creating Oracle Database"
    execute_as_opc jde-demo-db oracle "sh -c '
    export ORACLE_HOME=/u01/app/oracle/product/19.0.0/db_1
export PATH=\$ORACLE_HOME/bin:$PATH 
export ORACLE_SID=ORCL 
export PDB_NAME=JDEORCL 
exec dbca -silent -createDatabase                                              \
     -templateName General_Purpose.dbc                                         \
     -gdbname \${ORACLE_SID} -sid  \${ORACLE_SID} -responseFile NO_VALUE       \
     -characterSet AL32UTF8                                                    \
     -sysPassword ${db_sys_password}                                           \
     -systemPassword ${db_sys_password}                                        \
     -createAsContainerDatabase true                                           \
     -numberOfPDBs 1                                                           \
     -pdbName \${PDB_NAME}                                                     \
     -pdbAdminPassword ${db_sys_password}                                      \
     -databaseType MULTIPURPOSE                                                \
     -memoryMgmtType auto_sga                                                  \
     -totalMemory 4000                                                         \
     -storageType FS                                                           \
     -datafileDestination "/u01/oradata"                                       \
     -redoLogFileSize 1024                                                     \
     -emConfiguration NONE                                                     \
     -ignorePreReqs
    '"

    print_task "Post Database creation Configuration"

execute_as_opc jde-demo-db oracle "sh -c 'export ORACLE_HOME=/u01/app/oracle/product/19.0.0/db_1
export PATH=\$ORACLE_HOME/bin:$PATH 
export ORACLE_SID=ORCL 
export PDB_NAME=JDEORCL 
exec lsnrctl start'"

execute_as_opc jde-demo-db oracle "echo  'alter system set db_recovery_file_dest_size=60g;
alter system set sga_max_size=20g scope=spfile;
alter system set sga_target=20g scope=spfile;
alter system set filesystemio_options=setall scope=spfile;
alter system set processes=1500 scope=spfile;
shut immediate
startup
alter pluggable database all open;
alter pluggable database JDEORCL save state;
alter system register;
exit;
' > /tmp/db_update.sql"

execute_as_opc jde-demo-db oracle "sh -c 'export ORACLE_HOME=/u01/app/oracle/product/19.0.0/db_1
export PATH=\$ORACLE_HOME/bin:$PATH 
export ORACLE_SID=ORCL 
export PDB_NAME=JDEORCL 
exec sqlplus / as sysdba @/tmp/db_update.sql'"

execute_as_opc jde-demo-db oracle "echo  'jdeorcl=(DESCRIPTION=(CONNECT_DATA=(SERVICE_NAME=jdeorcl))(ADDRESS=(PROTOCOL=tcp)(HOST=jde-demo-db)(PORT=1521)))' > /tmp/tnsnames.ora"
execute_as_opc jde-demo-db oracle "cp -v  /tmp/tnsnames.ora /u01/app/oracle/product/19.0.0/db_1/network/admin"

execute_as_opc jde-demo-db oracle "echo 'export ORACLE_HOME=/u01/app/oracle/product/19.0.0/db_1' | sudo -u oracle tee -a /home/oracle/.bash_profile" 
execute_as_opc jde-demo-db oracle "echo 'export ORACLE_SID=ORCL' | sudo -u oracle tee -a /home/oracle/.bash_profile" 
execute_as_opc jde-demo-db oracle "echo 'export PATH=/u01/app/oracle/product/19.0.0/db_1/bin:\$PATH' | sudo -u oracle tee -a /home/oracle/.bash_profile" 

    ### EOF actual function betweens these comments
    echo -e "\nlog: $logfile"
    date              
 } 2>&1 | tee -a ${logfile}
}

stage_weblogic() {
 logfile=${log_path}/$(date +%Y%m%d_%H%M%S)_${FUNCNAME[0]}.log
 {
    date
    echo -e "\n\033[1m
         =========================================================================
         JD Edwards EntOne ON GCP TOOLKIT FUNCTION: ${FUNCNAME[0]}
         =========================================================================
         Function to provision Oracle WebLogic for the JDE
         ------------------------------------------------------------------------- \033[0m"
    
    
    print_task "Staging WLS Software on Database server:"
    execute_as_opc jde-demo-web oracle "mkdir -p /u01/app/oraInventory /u01/app/wls"
    execute_as_root jde-demo-web "echo -e 'inventory_loc=/u01/app/oraInventory\ninst_group=dba' | sudo tee /etc/oraInst.loc"
    copy_file_as_opc jde-demo-web oracle /u01/jdk-8u491-linux-x64.tar.gz /u01/jdk-8u491-linux-x64.tar.gz

    execute_as_opc jde-demo-web oracle "tar xzf /u01/jdk-8u491-linux-x64.tar.gz -C /u01"
    execute_as_opc jde-demo-web oracle "mv /u01/jdk1.8.0_491 /u01/jdk; /u01/jdk/bin/java -version"

    execute_as_opc jde-demo-web oracle "unzip -qo /u01/V994956-01.zip -d /u01/"

    execute_as_opc jde-demo-web oracle "echo 'export JAVA_HOME=/u01/jdk' | sudo -u oracle tee -a /home/oracle/.bash_profile" 
    execute_as_opc jde-demo-web oracle "echo 'export PATH=\$JAVA_HOME/bin:\$PATH' | sudo -u oracle tee -a /home/oracle/.bash_profile" 

    print_task "Installing Weblogic Software on Database server:"
    execute_as_opc jde-demo-web oracle "echo '
[ENGINE]
Response Version=1.0.0.0.0
[GENERIC]
ORACLE_HOME=/u01/app/wls
INSTALL_TYPE=WebLogic Server
DECLINE_AUTO_UPDATES=true' > /u01/wls.rsp"
        execute_as_opc jde-demo-web oracle "/u01/jdk/bin/java -jar /u01/fmw_14.1.1.0.0_wls.jar -silent -responseFile /u01/wls.rsp -invPtrLoc /etc/oraInst.loc"
    
    execute_as_opc jde-demo-web oracle "unzip -qo /u01/p39796866_141100_Generic.zip -d /u01/"
    execute_as_opc jde-demo-web oracle "unzip -qo /u01/p28186730_1394224_Generic.zip -d /u01/"

    execute_as_opc jde-demo-web oracle "/u01/jdk/bin/java -jar /u01/6880880/opatch_generic.jar  -silent oracle_home=/u01/app/wls  -invPtrLoc /etc/oraInst.loc"
    execute_as_opc jde-demo-web oracle "/u01/app/wls/OPatch/opatch  apply /u01/39796866 -silent oracle_home=/u01/app/wls  -invPtrLoc /etc/oraInst.loc"

    print_task "Creating Weblogic Domain:"
    
    execute_as_opc jde-demo-web oracle "sh -c '
    /u01/app/wls/oracle_common/common/bin/unpack.sh \
        -template=/u01/app/wls/wlserver/common/templates/wls/wls.jar \
        -domain=/u01/app/wls/user_projects/domains/base_domain \
        -user_name=weblogic \
        -password=${web_wls_password} '"

    execute_as_opc jde-demo-web oracle "sed -i 's/SecureListener=true/SecureListener=false/g' /u01/app/wls/user_projects/domains/base_domain/nodemanager/nodemanager.properties"

    print_task "Startup Weblogic & NodeManager:"
    execute_as_opc jde-demo-web oracle "sh -c 'nohup /u01/app/wls/user_projects/domains/base_domain/bin/startNodeManager.sh > /home/oracle/nodemanager.out 2>&1 &'"
    execute_as_opc jde-demo-web oracle "sh -c 'nohup /u01/app/wls/user_projects/domains/base_domain/startWebLogic.sh > /home/oracle/WebLogic.out 2>&1 &'"

    ### EOF actual function betweens these comments
    echo -e "\nlog: $logfile"
    date              
 } 2>&1 | tee -a ${logfile}
}

# create_and_dist_opc_key
# stage_jde_software
# start_jde_provisioning_server
# stage_oracle_database
# stage_weblogic