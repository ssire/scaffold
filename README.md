Case tracker pilote application
=======

The case tracker pilote application is a sample open source database application. It contains all the components of the *Oppidoc Business Application Development Framework* including the *Supergrid* formular generator. You can copy it or fork it to create new applications. For instance this can be used to create a Case Tracker application as documented in this [software documentation manual](https://github.com/ssire/case-tracker-manual).

The sample application out of the box maintains a database of persons and enterprises. It also supports the creation of cases and activities and can track them with a workflow. Note that for demonstration purpose the cases and activities address a workflow to coordinate the allocation of coaches to companies and to follow up the coaching activities. The pilote application does not implement the full workfow. You can get a full workflow in a commercial distribution by contacting the main author.

This is up to you to add more entities to the database or to replace exiting ones and to edit the workflow and the workflow documents. For that purpose, create the corresponding formulars into the *formulars* folder and create the corresponding CRUD controller into new modules that you can add to the *modules* folder. Use the Supergrid embedded application to generate the formulars for web rendering. Do not forget to edit the *config/mapping.xml* file to expose the new entities as REST resources and to modify the *epilogue.xql* script to add them to the application menu.

This application is written in XQuery / XSLT / Javascript and the [Oppidum](https://github.com/ssire/oppidum) web application framework. This is a full stack XML application.

This application has been supported by the CoachCom2020 coordination and support action (H2020-635518; 09/2014-08/2016). Coachcom 2020 has been selected by the European Commission to develop a framework for the business innovation coaching offered to the beneficiaries of the Horizon 2020 SME Instrument.

Several case tracker applications based on this skeleton are used in production since 2013 for the eldest, in Switzerland and in Belgium.

The case tracker pilote application is developped and maintained by Stéphane Sire at Oppidoc.

Dependencies
----------

Runs inside [eXist-DB](http://exist-db.org/) ([version 2.2](https://sourceforge.net/projects/exist/files/Stable/2.2/))

Back-end made with [Oppidum](https://www.github.com/ssire/oppidum/) XQuery framework

Front-end made with [AXEL](http://ssire.github.io/axel/), [AXEL-FORMS](http://ssire.github.io/axel/) and [Bootstrap](http://twitter.github.io/bootstrap/) (all embedded inside the `resources` folder)

Compatiblity
----------

The current version runs inside eXist-DB installed on Linux or Mac OS X environments only. The Windows environment is not yet supported. This requires some adaptations to the Oppidum framework amongst which to generate file paths with the file separator for Windows.

License
-------

The case tracker pilote application and the Oppidoc Business Application Development Framework are released as free software, under the terms of the LGPL version 2.1. 

You are welcome to join our efforts to improve the code base at any time and to become part of the contributors by making your changes and improvements and sending *pull* requests.

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
    git clone https://github.com/ssire/scaffold.git

#### Using SSH (if you registered your own SSH key inside your bitbucket profile)

    cd /usr/local/cctracker/lib/webapp/projects
    git clone git@github.com:ssire/scaffold.git

On Mac OS X you need to configure your SSH-agent to use you SSH Key (see available online tutorials)

### 4. Bootstrap case tracker pilote database

You must start your eXist-DB instance first

##### 4.1 Option 1 : creating an empty database

Execute the bootstrap script to pre-load application configuration data into the database. These files are read from the database when executing the application and not from the file system contrary to most other files (e.g. XQuery scripts).

    cd scripts
    ./bin/bootstrap.sh {admin-password}
    
Then execute the deployment script script/deploy.xql.

You can execute it directly from your browser by entering into the address bar :

    http:127.0.0.1:[PORT]/exist/projects/scaffold/admin/deploy?t=mesh,config,data,forms,stats,policies&pwd=[PASSWORD]&m=dev

or using curl from a terminal if available :

    curl -D - "http://127.0.0.1:[PORT]/exist/projects/scaffold/admin/deploy?t=mesh,config,data,forms,stats,policies&pwd=[PASSWORD]&m=dev"

or using wget from a terminal if available :

    sudo wget --no-check-certificate -O- "http://127.0.0.1:[PORT]/exist/projects/scaffold/admin/deploy?t=mesh,config,data,forms,stats,policies&pwd=[PASSWORD]&m=dev"

PASSWORD is the *admin* database password<br/>
Read header comments in `scripts/deploy.xql` to learn more about the different deployment targets.

**WARNING**: do not forget the *policies* target, which is required only the first time, to setup collection permissions, in particular for a specific permission category (owner, group or guest) the parent collection must be executable so that files can be read since eXist-DB 2.2.

##### 4.2 Option 2 : by restoring an existing database backup

You can restore a full database backup.

### 5. Open case tracker pilote application

You can start at [http://localhost:8080/exist/projects/scaffold]()

You can connect with the *admin* user of the database at first, then create one or more users using the *Add a person* button in the *Community > Persons* area. You can manage user roles in the *Users* tab in the *Admin* area.

Although you could create a case with the *admin* user this is not recommended since it is the only user without any person's record in the persons collection. Thus you should create at least one user with the *System Administrator* role and/or *Account Manager* role for that purpose. Give a user the *Software Developer* role to grant him/her access to the developer's menu.

### 6. Start creating cases and activities

If you started from scratch then you can only login with the *admin* user. You must then create a user with the account manager role, and create a login for that user. For that purpose :

* add the person from Community > Persons (click on *Add a person*)
* assign Account Manager role to that user from Admin > Users (you can also assign her the System Administrator role to allow her to administrate the other users)
* create a login for that user from Admin > Users 

you can then login with that user to create cases and activities


Coding conventions
---------------------

* _soft tabs_ (2 spaces per tab)
* no space at end of line (ex. with sed : `sed -E 's/[ ]+$//g'`)


