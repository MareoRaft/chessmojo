FROM perl:5.32-slim-buster


WORKDIR /home/matt/work


RUN cpan install Mojolicious::Lite
RUN cpan install Mojolicious::Static
RUN cpan install Mojo::Cache
RUN cpan install Mojo::IOLoop
RUN cpan install SVG
RUN cpan install FindBin
RUN cpan install Data::Dumper


COPY public public
COPY templates templates
COPY mojo.pl .
COPY move.pm .
COPY piece.pm .
COPY room.pm .
COPY setchess.pm .


# CMD ["hypnotoad", "mojo.pl"]
# CMD ["sleep", "999999"]
CMD ["perl", "./mojo.pl", "daemon", "-m", "production", "-l", "http://*:8080"]