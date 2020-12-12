# chessmojo!
Play chess with anybody online :)

You can access the site [here](http://learnnation.org/chess.html)!

A description of the chessmojo project can be found [here](http://matthewlancellotti.com/chessmojo/).


## FreeBSD 11.1 digital ocean server kick-off directions:

	sudo pkg install git
	git clone this project
	cd into this project
	cpan
	cpan install Mojolicious::Lite
	cpan install SVG
	cpan install Data::Dumper
	hypnotoad mojo.pl
	# or
	perl ./mojo.pl daemon -m production -l http://*:8080

Direct link is: http://45.55.107.156:8080


## Docker kickoff

The server deps and kick-off directions are programmatically specified in `prod.Dockerfile`, so the docker image is all you need to launch the project.

    docker build -t mvlancellotti/chessmojo:prod -f prod.Dockerfile . && docker run --rm -p 8080:8080 --name chessmojo-container mvlancellotti/chessmojo:prod


## Deploy

From dev laptop:

	docker push mvlancellotti/chessmojo:prod

From deployment server:

	docker pull mvlancellotti/chessmojo:prod
	docker run --rm -p 8080:8080 --name chessmojo-container mvlancellotti/chessmojo:prod




