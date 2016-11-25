Case tracker pilote application
=======

The case tracker pilote application is a sample database application which can be copied or forked to create new applications using the embedded Supergrid form generator. For instance this can be used to create a [Case Tracker](https://github.com/ssire/case-tracker-manual) application.

The application out of the box allows to maintain a database of persons and enterprises. The application will allow (soon) to create cases and activities and to track them with a workflow. Note that for demonstration purpose the cases and activities address a workflow to coordinate the allocation of coaches to companies and to follow up the coaching activities. 

This is up to you to add more entities to the database or to replace exiting ones and to edit the workflow and the workflow documents. For that purpose, create the corresponding formulars into the *formulars* folder and create the corresponding CRUD controller into new modules that you can add to the *modules* folder. Use the Supergrid embedded application to generate the formulars for web rendering. Do not forget to edit the *config/mapping.xml* file to expose the new entities as REST resources and to modify the *epilogue.xql* script to add them to the application menu.

This application is written in XQuery / XSLT / Javascript. This is a full stack XML application.

This application has been supported by the CoachCom2020 coordination and support action (H2020-635518; 09/2014-08/2016). Coachcom 2020 has been selected by the European Commission to develop a framework for the business innovation coaching offered to the beneficiaries of the Horizon 2020 SME Instrument.

Several case tracker applications based on this skeleton are used in production since 2013 for the eldest, in Switzerland and in Belgium.

The case tracker pilote application is developped and maintained by Stéphane Sire at Oppidoc.

Dependencies
----------

Runs inside [eXist-DB](http://exist-db.org/) ([version 2.2](https://sourceforge.net/projects/exist/files/Stable/2.2/))

Back-end made with [Oppidum](https://www.github.com/ssire/oppidum/) XQuery framework

Front-end made with [AXEL](http://ssire.github.io/axel/), [AXEL-FORMS](http://ssire.github.io/axel/) and [Bootstrap](http://twitter.github.io/bootstrap/) (all embedded inside the `resources` folder)

License
-------

Case tracker pilote application is released as free software, under the terms of the LGPL version 2.1. You are welcome to join our efforts to improve the code base at any time and to become part of the contributors.

Installation
------------

### 1. Install eXist-DB

Follow [exist db installation notes](https://github.com/ssire/oppidum/wiki/exist-db-installation-notes)

### 2. Install Oppidum

Follow the [How to install it ?](http://www.github.com/ssire/oppidum/) section of Oppidum README file

Following these instructions you should get Oppidum inside `/usr/local/scaffold/lib/webapp/projects/oppidum` and available at [http://localhost:8080/exist/projects/oppidum]()

Do not forget to execute Oppidum post-installation script _bootstrap.sh_ as explained. Always check `EXIST-HOME/client.properties` points to the correct port before executing it

### 3. Clone case tracker pilote

Note that inherently to Oppidum you need to clone all your projects inside the same _projects_ folder inside eXist-DB _webapp_ folder

#### Using HTTPS

    cd /usr/local/scaffold/lib/webapp/projects
    git clone https://{your login}@bitbucket.org/ssire/scaffold.git

#### Using SSH (if you registered your own SSH key inside your bitbucket profile)

    cd /usr/local/cctracker/lib/webapp/projects
    git clone git@bitbucket.org:votre-login-bitbucket/cctracker.git

On Mac OS X you need to configure your SSH-agent to use you SSH Key (see available online tutorials)

### 4. Bootstrap case tracker pilote database

You must start your eXist-DB instance first

##### 4.1 Option 1 : creating an empty database

Execute the bootstrap script to pre-load application configuration data into the database. These files are read from the database when executing the application and not from the file system contrary to most other files (e.g. XQuery scripts).

    cd scripts
    ./bin/bootstrap.sh {admin-password}
    
Then execute the deployment script script/deploy.xql.

You can execute it directly from your browser by entering into the address bar :

    http:127.0.0.1:[PORT]/exist/projects/scaffold/admin/deploy?t=config,data,forms&pwd=[PASSWORD]&m=dev

or using curl from a terminal if available :

    curl -D - "http://127.0.0.1:[PORT]/exist/projects/scaffold/admin/deploy?t=config,data,forms&pwd=[PASSWORD]&m=dev"

or using wget from a terminal if available :

    sudo wget --no-check-certificate -O- "http://127.0.0.1:[PORT]/exist/projects/scaffold/admin/deploy?t=config,data,forms&pwd=[PASSWORD]&m=dev"

PASSWORD is the *admin* database password<br/>
Read header comments in `scripts/deploy.xql` to learn more about the different deployment targets.

##### 4.2 Option 2 : by restoring an existing database backup

You can restore a full database backup.

### 5. Open case tracker pilote application

You can start at [http://localhost:8080/exist/projects/scaffold]()

You can connect with the *admin* user of the database at first, then create one or more users using the *Add a person* button in the *Community > Persons* area. You can manage user roles in the *Users* tab in the *Admin* area. By default users with the *System Administrator* role are able to create other users.

Coding conventions
---------------------

* _soft tabs_ (2 spaces per tab)
* no space at end of line (ex. with sed : `sed -E 's/[ ]+$//g'`)


