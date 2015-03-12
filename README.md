salWHD
======

Docker container for sal + Sal-WHDImport + JSSImport

This is a Docker container that pulls from [Sal](https://github.com/macadmins/sal), incorporates [Sal-WHD](https://github.com/nmcspadden/Sal-WHDImport) and [Sal-JSS](https://github.com/nmcspadden/Sal-JSSImport).

How To Setup Sal, Sal-WHD, and JSSImport with Docker:
=========

Preparing Data Files:
------

1. `mkdir -p /usr/local/sal_data/settings/`
2. `curl -o /usr/local/sal_data/settings/settings.py https://raw.githubusercontent.com/macadmins/sal/master/settings.py`
	1. Make the following changes to settings.py:  
		Add `'whdimport',` to the end of the list of `INSTALLED_APPS`
3. `git clone https://github.com/nmcspadden/MacModelShelf.git /usr/local/sal_data/macmodelshelf`

Run the Sal DB and Setup Scripts:
-------


1. `docker run --name "sal-db-data" -d --entrypoint /bin/echo grahamgilbert/postgres Data-only container for postgres-sal`
2. `docker run --name "postgres-sal" -d --volumes-from sal-db-data -e DB_NAME=sal -e DB_USER=saldbadmin -e DB_PASS=password --restart="always" grahamgilbert/postgres`

Run the JSS Import DB:
----
1.	`docker run --name "jssi-db-data" -d --entrypoint /bin/echo macadmins/postgres Data-only container for jssimport-db`
2.	`docker run --name "jssimport-db" -d --volumes-from jssi-db-data -e DB_NAME=jssimport -e DB_USER=jssdbadmin -e DB_PASS=password --restart="always" macadmins/postgres`


Run the WHD DB:
-----

1. `docker run -d --name whd-db-data --entrypoint /bin/echo macadmins/postgres Data-only container for postgres-whd`
2. `docker run -d --name postgres-whd --volumes-from whd-db-data -e DB_NAME=whd -e DB_USER=whddbadmin -e DB_PASS=password macadmins/postgres`

Run Temporary Sal to Prepare Initial Data Migration:
-----

If you want to load data from an existing Sal implementation, use `python
manage.py dumpdata --format json > saldata.json` to export
the data, and then place the saldata.json into /usr/local/sal_data/saldata/.  
Add `-v /usr/local/sal_data/saldata:/saldata` to the command below (after the other -v) if you want to do this:  

1. `docker run --name "sal-loaddata" --link postgres-sal:db -e ADMIN_PASS=password -e DB_NAME=sal -e DB_USER=saldbadmin -e DB_PASS=password -it --rm -v /usr/local/sal_data/settings/settings.py:/home/docker/sal/sal/settings.py macadmins/salwhd /bin/bash`
	1. `cd /home/docker/sal`
	2. `python manage.py syncdb --noinput`
    3. `python manage.py migrate --noinput`
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

1. `ddocker run -d --name sal -p 81:8000 --link postgres-sal:db -e ADMIN_PASS=password -e DB_NAME=sal -e DB_USER=saldbadmin -e DB_PASS=password -v /usr/local/sal_data/settings/settings.py:/home/docker/sal/sal/settings.py macadmins/salwhd`
2. `docker exec sal python /home/docker/sal/manage.py syncmachines`

Run JSSImport and Sync the Database:
----
`docker run --rm --name jssi --link jssimport-db:db -e DB_NAME=jssimport -e DB_USER=jssdbadmin -e DB_PASS=password -e JSS_USER=user -e JSS_PASS=password -e JSS_URL=https://casper:8443 macadmins/jssimport`

Run WHD with its data-only container:
-----

1. `docker run -d --name whd-data --entrypoint /bin/echo macadmins/whd Data-only container for whd`
2. `docker run -d -p 8081:8081 --link postgres-sal:saldb --link postgres-whd:db --link jssimport-db:jdb --name "whd" --volumes-from whd-data macadmins/whd`

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

1. Setup discovery connection "Sal":
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
      4. Host: jdb
      5. Port: 5432
      6. Database Name: jssimport
      7. Username: jssdbadmin
      8. Password: password
      9. Schema: Public
      10. Table or View: casperimport
      11. Sync Column: serial
