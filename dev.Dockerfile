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


# I recommend using the `sleep 999999` command and then manually running `morbo mojo.pl` in the container because morbo is  made specifically for development, and hence auto-updates what is served.
# see https://docs.mojolicious.org/morbo
# actually, for MORBO, it works fine directly
CMD ["morbo", "mojo.pl"]
# CMD ["hypnotoad", "mojo.pl"]
# CMD ["sleep", "999999"]
# CMD ["perl", "./mojo.pl", "daemon", "-l", "http://*:8080"]
