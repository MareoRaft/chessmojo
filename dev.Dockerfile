FROM perl:5.32-slim-buster


WORKDIR /home/matt/work


RUN cpan install Mojolicious::Lite
RUN cpan install Mojolicious::Static
RUN cpan install Mojo::Cache
RUN cpan install Mojo::IOLoop
RUN cpan install SVG
RUN cpan install FindBin
RUN cpan install Data::Dumper
RUN cpan install Mojolicious::Plugin::AutoReload


# Instead of `COPY src src`, you should use docker's -v feature to use the dev files


CMD ["morbo", "mojo.pl"]
