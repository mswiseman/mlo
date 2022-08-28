#!/usr/bin/perl -w
use warnings; use strict; use LWP::Simple;
#this is a script that was written by Nancy Garnhardt for RLE to accept a list of genes and a fast form$
#file of sequences, and to pull out the sequences of the genes named in the list.
if( @ARGV < 3 ) {
        print "USAGE: sequencefilename genenamesfilename resultfilename\n\n";
        exit;
}
my $SEQ_FILE = &openFile( shift( @ARGV ) ); # open the input file (or die) my $GENE_NAMES_FILE = &openF$
shift( @ARGV ) ); # open the input file (or die) my $OUT_FILE; unless( open( $OUT_FILE, ">" . shift( @A$
) ) {
   print "Cannot open file to write to!!\n\n";
   exit;
}
while( my $gene_name = <$GENE_NAMES_FILE> ) #get the gene name {
        chomp( $gene_name );
        #print "The gene is $gene_name\n";
        if( length( $gene_name ) > 1 )
        {
                #go through the sequence file looking for this name
                while( my $line = <$SEQ_FILE> )
                {
                        if( $line =~ m/$gene_name/ )
                        {
                          print $OUT_FILE $line;
                          $line = <$SEQ_FILE>; #get the sequence
                          print $OUT_FILE $line;
                          last; #go to the next name

                        }
                }

        seek $SEQ_FILE, 0, 0; #reset file ptr to beginning of file
        }
}
#--------------- openFile -----------------------------------
# $fileHandleRef = openFile( $fileName )
#
# Open the file whose name is passed. If successful, return a reference to the file handle.
#
use File::Spec; sub openFile() {
   my ( $fileName ) = @_;
   my $FILEHANDLE;

   # get a full path name -- needed for some IDE environments
   my @path     = File::Spec->splitdir( File::Spec->rel2abs( $0 ) );
   $fileName    = File::Spec->catfile( @path[0 .. $#path - 1], $fileName );
   print "Opening: $fileName\n";

   open ( $FILEHANDLE, $fileName ) or die "Unable to open: " . $FILEHANDLE ;
   return $FILEHANDLE;
}
sub usage() {
   print STDERR "Enter name of ko results file\n "
}
