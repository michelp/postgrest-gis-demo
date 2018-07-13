# PostgREST GIS Demo
    
A guide to using [PostGIS](https://postgis.net/) and
[PostgREST](https://postgrest.org/en/v5.0/) to visualize data from
[ADSBExchange](https://www.adsbexchange.com/).

= Intro =

Before beginning, make sure you have [Docker](https://www.docker.com/)
and [Docker Compose](https://docs.docker.com/compose/) installed on
your test machine.

To start the demo, clone this repo, and run the command:

    docker-compose up -d

You will see the containers pull and build, this may take some time.
After the build is complete, you can verify that all the services are
running with `docker-compose ps`:

    docker-compose ps
    ...
    ...

If the up command failed, check that no other programs are using the
ports specified in `docker-compose.yml`

Now point your browser to `http://localhost:`
