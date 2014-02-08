#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(:5.12);
use autodie qw(:all);
use Getopt::Long qw(GetOptionsFromArray);
use Pod::Usage qw(pod2usage);
use Mac::iTunes::Library::XML;
use Try::Tiny;
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

    defined $library_file or die "No input library file specified\n";

    -f $library_file or die "Not a file '$library_file'\n";

    my $library = Mac::iTunes::Library::XML->parse($library_file);

    defined $database_file or die "No database file specified\n";

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

