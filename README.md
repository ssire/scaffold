Case tracker pilote
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

Runs inside [eXist-DB](http://exist-db.org/) (developed with [version 2.2](https://bintray.com/existdb/releases/exist))

Back-end made with [Oppidum](https://www.github.com/ssire/oppidum/) XQuery framework

Front-end made with [AXEL](http://ssire.github.io/axel/), [AXEL-FORMS](http://ssire.github.io/axel/) and [Bootstrap](http://twitter.github.io/bootstrap/) (all embedded inside the *resources* folder)

Compatiblity
----------

The current version runs inside eXist-DB installed on Linux or Mac OS X environments only. The Windows environment is not yet supported. This requires some adaptations to the Oppidum framework amongst which to generate file paths with the file separator for Windows.

License
-------

The case tracker pilote application and the Oppidoc Business Application Development Framework are released as free software, under the terms of the LGPL version 2.1. 

You are welcome to join our efforts to improve the code base at any time and to become part of the contributors by making your changes and improvements and sending *pull* requests.

Installation
------------

To run the scaffold application you need to 

1. install [eXist-DB](https://bintray.com/existdb/releases/exist) (the application has been developed with eXist-DB 2.2), you can follow these [installation notes](https://github.com/ssire/oppidum/wiki/exist-db-installation-notes)
2. create a projects folder directly inside the webapp folder of your eXist-DB installation, you should call it *projects*
3. install Oppidum inside your *projects* folder, you can follow [How to install it ?](http://www.github.com/ssire/oppidum/) section of the Oppidum README file
4. clone this depot into your *projects* folder as a sibling of the *oppidum* folder, then :
    * go to the `scaffold/scripts` folder of this depot and run the *bootstrap.sh* command with the DB admin password as parameter
    * open the following URL to run the **deployment script** (you can use curl or wget command line too) : `http://localhost:PORT/exist/projects/scaffold/admin/deploy?t=config,data,forms,mesh,templates,stats,users,bootstrap,policies&pwd=[ADMIN PASSWORD]`
        * this will create a *demo* user (password *test*) that you can use to connect to the application as a system administrator, developer and account manager
        * this will also create a *coach* user (password *test*) that you can use to connect to the application as a coach

Note that in all the instructions above before running the *bootstrap.sh* script always check `EXIST-HOME/client.properties` points to the correct PORT before executing it in case you adjusted the default eXist-DB port (8080).

Assuming you installed eXist-DB into `/usr/local/scaffold/lib`, here are the commands to execute to get it running :

    cd /usr/local/scaffold/lib
    ./bin/startup.sh & # starts eXist-DB; skip this if already running !
    mkdir -p webapp/projects
    cd webapp/projects
    git clone https://github.com/ssire/oppidum.git
    cd oppidum/scripts
    ./bootstrap.sh "admin PASSWORD"
    # you can open http://localhost:PORT/exist/projects/oppidum to check Oppidum installation
    cd ../..
    git clone https://github.com/ssire/scaffold.git
    cd scaffold/scripts
    ./bootstrap.sh "admin PASSWORD"
    curl -D - "http://localhost:PORT/exist/projects/scaffold/admin/deploy?t=config,data,forms,mesh,templates,stats,users,bootstrap,policies&pwd=[admin PASSWORD]"
    # or wget -O- [same address as the two lines above]

You can then open [http://localhost:PORT/exist/projects/scaffold]() and login with *demo* (password: *test*). 

From there you can create one or more users using the *Add a person* button in the *Community > Persons* area and you can manage user's roles in the *Users* tab in the *Admin* section since the *demo* user is a system administrator. You can also create cases since the *demo* user is also an account manager. Finally you can access the developer's menu since the *demo* user is also a developer.

Read header comments in `scripts/deploy.xql` to learn more about the different deployment targets.

## Trouble shooting

#### Setting up an admin password

You need to setup a database admin password to run the *bootstrap.sh* scripts. In case your forgot it you can quickly use the java admin client in command line mode :

    $ cd /usr/local/scaffold/lib/
    $ ./bin/client.sh -s
    -s
    Using locale: fr_FR.UTF-8
    eXist version 2.2 (master-5c5aadc), Copyright (C) 2001-2017 The eXist-db Project
    eXist-db comes with ABSOLUTELY NO WARRANTY.
    This is free software, and you are welcome to redistribute it
    under certain conditions; for details read the license file.


    type help or ? for help.
    exist:/db>passwd admin
    password: ***
    re-enter password: ***
    exist:/db>quit

#### Running the application deployment script

It seems you must not be logged to the scaffold application to run the deployment script `/admin/deploy`. So in case your try to run it multiple times, if you get an error, logout and run it again. 

The *users*, *bootstrap* and *policies* targets are required only the first time, to create the initial `persons.xml` and `enterprises.xml` resources, and to setup collection permissions. DO NOT re-run the *bootstrap* target if you have created more users or enterprises because they would be lost.

Coding conventions
---------------------

* _soft tabs_ (2 spaces per tab)
* no space at end of line (ex. with sed : `sed -E 's/[ ]+$//g'`)
