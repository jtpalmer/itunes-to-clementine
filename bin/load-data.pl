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
    my ( $help, $verbose, $quiet, $debug, $library_file, $database_file );

    GetOptionsFromArray(
        \@_,
        'help|h'       => \$help,
        'verbose|v'    => \$verbose,
        'quiet|v'      => \$quiet,
        'debug'        => \$debug,
        'library|l=s'  => \$library_file,
        'database|d=s' => \$database_file,
    ) or pod2usage();

    pod2usage( -exitval => 0, -verbose => 2 ) if $help;

    defined $library_file  or die "No library file specified\n";
    defined $database_file or die "No database file specified\n";

    -f $library_file  or die "Not a file '$library_file'\n";
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

    $ load-data --library iTunes.xml --database clementine.db

=head1 DESCRIPTION

Load song ratings from an iTunes library XML file into Clementine's
database.

=head1 OPTIONS

=over 4

=item B<-h>, B<--help>

Output help text.

=item B<-v>, B<--verbose>

Display verbose output.

=item B<-q>, B<--quiet>

Only output errors.

=item B<--debug>

Display debugging output.

=item B<-l> I<library-file>, B<--library>=I<library-file>

iTunes library xml file to use.

=item B<-d> I<database-file>, B<--database>=I<database-file>

The clemntine database file to update.

=back

=head1 RETURN VALUE

Returns 0 in success and non-zero on failure.

=head1 ERRORS

Exceptions, error return codes, exit statuses, and errno settings.

=head1 EXAMPLES

Run the program:

    example --example

=head1 FILES

=head1 NOTES

Miscellaneous commentary.

=head1 SEE ALSO

=over 4

=item * L<Mac::iTunes::Library::XML>

=back

=cut

