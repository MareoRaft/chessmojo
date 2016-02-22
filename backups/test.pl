use Mojolicious::Lite;

# Authenticate based on name parameter
under sub {
  my $self = shift;

  # Authenticated
  my $name = $self->param('name') || '';
  return 1 if $name eq 'Bender';

  # Not authenticated
  $self->render('denied');
  return undef;
};

# Only reached when authenticated
get '/yolo' => 'index';

app->start;
__DATA__

@@ denied.html.ep
You are not Bender, permission denied.

@@ index.html.ep
Hi Bender.
