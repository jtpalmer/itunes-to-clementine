#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(:5.12);
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage qw(pod2usage);
use Mac::iTunes::Library::XML;
use DBI;

main(@ARGV);

sub main {
    my ( $help, $verbose, $debug, $library_file, $database_file );

    GetOptionsFromArray(
        \@_,
        'help|h'      => \$help,
        'verbose|v'   => \$verbose,
        'debug|d'     => \$debug,
        'library|l=s' => \$library_file,
        'database=s'  => \$database_file,
    ) or pod2usage();

    pod2usage( -exitval => 0, -verbose => 2 ) if $help;

    defined $library_file or die "No library file specified\n";
    defined $database_file or die "No database file specified\n";

    -f $library_file or die "Not a file '$library_file'\n";
    -f $database_file or die "Not a file '$database_file'\n";

    my $library = Mac::iTunes::Library::XML->parse($library_file);

    my $dbh = DBI->connect( 'dbi:SQLite:dbname=' . $database_file )
        or die "Failed to connect to database: " . $DBI::errstr . "\n";

    my $sql = 'UPDATE songs SET rating = ? WHERE artist = ? and title = ?';
    my $sth = $dbh->prepare($sql);

    say 'Track count: ' . $library->num();

    my %items = $library->items();
    while ( my ( $artist_name, $songs ) = each %items ) {
        say 'Artist: ' . $artist_name;
        while ( my ( $song_name, $song_items ) = each %$songs ) {
            say 'Song: ' . $song_name;
            my $rating;
            for my $item (@$song_items) {
                $rating = $item->rating() // 0;
                say 'Rating: ' . $rating;
            }

            $sth->execute( $rating / 100, $artist_name, $song_name );
        }
        say '-' x 76;
    }

    exit;
}

__END__

=pod

=head1 SYNOPSIS

    $ my-script.pl

=head1 DESCRIPTION

What does this script do?

=head1 OPTIONS

=over 4

=item B<--section>=I<manext>

=item B<-s> I<manext>, B<--section>=I<manext>

=back

=head1 RETURN VALUE

Returns 0 in success and non-zero on failure.

=head1 ERRORS

Exceptions, error return codes, exit statuses, and errno settings.

=head1 EXAMPLES

Run the program:

    example --example

=head1 ENVIRONMENT

=over 4

=item HOME

Used to determine the user's home directory.  F<.foorc> in this
directory is read for configuration details, if it exists.

=back

=head1 FILES

=head1 CAVEATS

Things to take special care with.

=head1 BUGS

These things are broken.

=head1 RESTRICTIONS

These things won't be fixed.

=head1 NOTES

Miscellaneous commentary.

=head1 SEE ALSO

=over 4

=item * L<perl>

=back

=cut

