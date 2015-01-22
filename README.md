salWHD
======

Docker container for sal + Sal-WHDImport + JSSImport

This is a Docker container that pulls from [Sal](https://github.com/macadmins/sal), incorporates [Sal-WHD](https://github.com/macadmins/Sal-WHDImport) and [Sal-JSS](https://github.com/macadmins/Sal-JSSImport).

How To Setup Sal, Sal-WHD, and JSSImport with Docker:
=========

Preparing Data Files:
------

1. `mkdir -p /usr/local/sal_data/settings/`
2. `curl -o /usr/local/sal_data/settings/settings.py https://raw.githubusercontent.com/macadmins/sal/master/settings.py`
	1. Make the following changes to settings.py:  
		Add `'whdimport'`, to `INSTALLED_APPS`
3. `curl -o /usr/local/sal_data/com.github.nmcspadden.prefs.json https://raw.githubusercontent.com/nmcspadden/Sal-JSSImport/master/com.github.nmcspadden.prefs.json`
	1. Change password
4. `curl -o /usr/local/sal_data/com.github.sheagcraig.python-jss.plist https://raw.githubusercontent.com/nmcspadden/Sal-JSSImport/master/com.github.sheagcraig.python-jss.plist`
	1. Setup API user, host, and password
5. `git clone https://github.com/nmcspadden/MacModelShelf.git /usr/local/sal_data/macmodelshelf`

Preparing Database Setup Scripts:
-----

2. `curl -O https://raw.githubusercontent.com/macadmins/salWHD/master/setup_jssi_db.sh`
      1. `chmod +x setup_jssi_db.sh`
      2. Change DB settings:
        1. DB_NAME=jssimport
        2. DB_USER=jssdbadmin
        3. DB_PASS=password
3. `curl -O https://raw.githubusercontent.com/macadmins/whdDocker/master/setup_whd_db.sh`
      1. `chmod +x setup_whd_db.sh`
      2. Change DB settings:
        1. DB_NAME=whd
        2. DB_USER=whddbadmin
        3. DB_PASS=password

Run the Sal DB and Setup Scripts:
-------


1. `docker run --name "sal-db-data" -d --entrypoint /bin/echo grahamgilbert/postgres Data-only container for postgres-sal`
2. `docker run --name "postgres-sal" -d --volumes-from sal-db-data -e DB_NAME=sal -e DB_USER=saldbadmin -e DB_PASS=password --restart="always" grahamgilbert/postgres`
3. `./setup_jssi_db.sh`

Run the WHD DB To Prepare the Configurations:
-----

1. `docker run -d --name whd-db-data --entrypoint /bin/echo macadmins/postgres-whd Data-only container for postgres-whd`
2. `docker run -d --name postgres-whd --volumes-from whd-db-data macadmins/postgres-whd`
3. `./setup_whd_db.sh`

Run Temporary Sal to Prepare Initial Data Migration:
-----

If you want to load data from an existing Sal implementation, use `python
manage.py dumpdata --format json > saldata.json` to export
the data, and then place the saldata.json into /usr/local/sal_data/saldata/.

1. `docker run --name "sal-loaddata" --link postgres-sal:db -e ADMIN_PASS=password -e DB_NAME=sal -e DB_USER=saldbadmin -e DB_PASS=password -i -t --rm -v /usr/local/sal_data/saldata:/saldata -v /usr/local/sal_data/settings/settings.py:/home/docker/sal/sal/settings.py macadmins/salwhd /bin/bash`
	1. `cd /home/docker/sal`
	2. `python manage.py syncdb --noinput`
    3. `python manage.py migrate`
    4. `echo "TRUNCATE django_content_type CASCADE;" | python manage.py dbshell | xargs`
        1. Equivalent to:  
       `# python manage.py dbshell`  
       `TRUNCATE django_content_type CASCADE;`
       `\q`
    5. `python manage.py schemamigration whdimport --auto`
    6. `python manage.py migrate whdimport`
    7. **If you want to import data : ** `python manage.py loaddata /saldata/saldata.json`
    8. `exit`
2. After exiting, the temporary "sal-loaddata" container is removed.

Run Sal and Sync the Database:
-----

1. `docker run -d --name="sal" -p 80:8000 --link postgres-sal:db -e ADMIN_PASS=password -e DB_NAME=sal -e DB_USER=saldbadmin -e DB_PASS=password -v /usr/local/sal_data/settings/settings.py:/home/docker/sal/sal/settings.py -v /usr/local/sal_data/com.github.sheagcraig.python-jss.plist:/home/docker/sal/jssimport/com.github.sheagcraig.python-jss.plist -v /usr/local/sal_data/com.github.macadmins.prefs.json:/home/docker/sal/jssimport/com.github.macadmins.prefs.json macadmins/salwhd`
2. `docker exec sal python /home/docker/sal/manage.py syncmachines`

Sync/Import the JSS into the Database:
-----

1. `docker exec sal python /home/docker/sal/jssimport/jsspull.py --dbprefs "/home/docker/sal/jssimport/com.github.macadmins.prefs.json" --jssprefs "/home/docker/sal/jssimport/com.github.sheagcraig.python-jss.plist"`

Run WHD with its data-only container:
-----

1. `docker run -d --name whd-data --entrypoint /bin/echo macadmins/whd Data-only container for whd`
2. `docker run -d -p 8081:8081 --link postgres-sal:saldb --link postgres-whd:db --name "whd" --volumes-from whd-data macadmins/whd`

Configure WHD Through Browser:
----

1. Open Web Browser: http://localhost:8081
2. Set up using Custom SQL Database:
	1. Database type: postgreSQL (External)
	2. Host: db
	3. Port: 5432
	4. Database Name: whd
	5. Username: whddbadmin
	6. Password: password
3. Skip email customization
4. Setup administrative account/password
5. Choose "IT General/Other"

Setup Discovery Connections:
----

1. Setup discovery disconnection "Sal":
	1. Connection Name: "Sal" (whatever you want)
	2. Discovery Tool: Database Table or View
	3. Database Type: PostgreSQL - **uncheck Use Embedded Database**
	4. Host: saldb
	5. Port: 5432
	6. Database Name: sal
	7. Username: saldbadmin
	8. Password: password
	9. Schema: Public
	10. Table or View: whdimport_whdmachine
	11. Sync Column: serial
2. Setup discovery connection "Casper":
      1. Connection Name: "Casper" (whatever you want)
      2. Discovery Tool: Database Table or View
      3. Database Type: PostgreSQL - **uncheck Use Embedded Database**
      4. Host: saldb
      5. Port: 5432
      6. Database Name: jssimport
      7. Username: jssdbadmin
      8. Password: password
      9. Schema: Public
      10. Table or View: casperimport
      11. Sync Column: serial
