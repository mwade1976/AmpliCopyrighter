#!/usr/bin/env perl

# 16S_from_IMG
# Copyright 2012 Adam Skarshewski
# You may distribute this module under the terms of the GPLv3


=head1 NAME

16S_from_IMG - Extract 16S from IMG genomes

=head1 SYNOPSIS

  16S_from_IMG.pl -i <folder_containing_taxon_subfolders>

=head1 DESCRIPTION

Get 16S sequences from folders of IMG taxon ids (with gffs and gene fasta files).
The results are written in FASTA format on stdout.

=head1 REQUIRED ARGUMENTS

=over

=item -i <input_dir>

Input directory, containing folders of IMG taxon IDs.

=for Euclid:
   input_dir.type: readable

=back

=head1 AUTHOR

Adam Skarshewski

=head1 BUGS

All complex software has bugs lurking in it, and this program is no exception.
If you find a bug, please report it on the bug tracker:
L<http://github.com/fangly/AmpliCopyrighter/issues>

=head1 COPYRIGHT

Copyright 2012 Adam Skarshewski

Copyrighter is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
Copyrighter is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with Copyrighter.  If not, see <http://www.gnu.org/licenses/>.

=cut


use strict;
use warnings;
use Getopt::Euclid qw(:minimal_keys);
use Bio::SeqIO;
use File::Spec;

my %genes;
my $input_dir = $ARGV{'i'};
my $out_fh = Bio::SeqIO->new(-format => 'fasta');
opendir my $dh, $input_dir or die "Error: Could not read folder $input_dir\n$!\n";
while (my $entry = readdir($dh)) {
   my $gff_file = File::Spec->catfile($input_dir, $entry, "$entry.gff");
   if (-e $gff_file) {
      open my $fh, '<', $gff_file or die "Error: Could not read file $gff_file\n$!\n";
      while (my $line = <$fh>) {
         chomp $line;
         my @splitline = split /\t/, $line;
         if (scalar(@splitline) < 9) {
            next;
         }
         if ($splitline[2] eq 'rRNA') {
            if ($splitline[8] =~ /16S/i && $splitline[8] =~ /ID=(\d+)/) {
               $genes{$1} = $entry;
            }
         }
      }
      my $fasta_file = File::Spec->catfile($input_dir, $entry, "$entry.genes.fna");
      if (-e $fasta_file) {
         my $in_fh = Bio::SeqIO->new(-format => 'fasta',
                                     -file   => $fasta_file);
         while (my $seq_obj = $in_fh->next_seq()) {
            if (exists($genes{$seq_obj->id()})) {
               # Rename read as <genomeid>_<geneid>
               my $new_id = $genes{$seq_obj->id()} . '_' . $seq_obj->id();
               $seq_obj->id($new_id);
               $out_fh->write_seq($seq_obj)
            }
         }
      }
   }
}
closedir $dh;
$out_fh->close;

exit;
