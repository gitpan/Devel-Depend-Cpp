
package Devel::Depend::Cpp;

use 5.006;
use strict ;
use warnings ;
use Carp ;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.01';

#------------------------------------------------------------------------------------------------

sub Depend
{
my $file_to_depend          = shift || confess "No file to depend!\n" ;
my $switches                = shift ;
my $include_system_includes = shift ;
my $add_child_callback      = shift ;
my $display_cpp_output      = shift ;

my $command = "cpp -H -M $switches $file_to_depend 2>&1" ;
my $errors ;

my @cpp_output = `$command` ;
$errors = "command: $command : $!" unless @cpp_output ;

for(@cpp_output)
	{
	$errors .= $_ if(/No such file or directory/) ;
	}
	
if($include_system_includes)
	{
	@cpp_output = grep {/^\./} @cpp_output ;
	}
else
	{
=comment
Default search path from cpp Info pages:
/usr/local/include
/usr/lib/gcc-lib/TARGET/VERSION/include
/usr/TARGET/include
/usr/include
/usr/include/g++-v3
=cut
	@cpp_output = grep {! m~\.+\s+/usr/~ && /^\./} @cpp_output ;
	}
	
my %nodes ;
my %node_levels ;
my %parent_at_level = (0 => {__NAME => $file_to_depend}) ;

for(@cpp_output)
	{
	print STDERR $_ if($display_cpp_output) ;
	
	chomp ;
	my ($level, $name) = /^(\.+)\s+(.*)/ ;
	$level = length $level ;
	
	my $node ;
	if(exists $nodes{$name})
		{
		$node = $nodes{$name} ;
		}
	else
		{
		$nodes{$name} = {__NAME => $name} ;
		$node = $nodes{$name} ;
		}
		
	$node_levels{$level}{$name} = $node unless exists $node_levels{$level}{$name} ;
	
	$parent_at_level{$level} = $node ;
	
	my $parent = $parent_at_level{$level - 1} ;
	
	unless(exists $parent->{$name})
		{
		$parent->{$name} = $node ;
		$add_child_callback->($parent->{__NAME} => $name) if(defined $add_child_callback) ;
		}
	}
	
return((! defined $errors), \%node_levels, \%nodes, $errors) ;
}

#-------------------------------------------------------------------------------

1 ;


=head1 NAME

Devel::Depend::Cpp - Perl extension for extracting dependency trees using 'cpp'

=head1 SYNOPSIS

  use Devel::Depend::Cpp;
  
 my ($success, $includ_levels, $included_files) = Devel::Depend::Cpp::Depend
 							(
 							  '/usr/include/stdio.h'
 							, '' # switches to cpp
 							, 0 # include system includes
 							) ;

=head1 DESCRIPTION

I<Depend> calls B<cpp> (the c pre-processor) to extract all the included files. If the call succeds,
I<Depend> returns a list consiting of the following items:

=over 2

=item [1] Success flag set to 1

=item [2] A reference to a hash where the included files are sorted per level. (A file can appear at different levels)

=item [3] A reference to a hash representing an include tree

=back

If the call faills, I<Depend> returns a list consiting of the following items:

=over 2

=item [1] Success flag set to 0

=item [2] A string containing an error message

=back


I<Depend> takes the following arguments:

=over 2

=item 1/ The name of the file to depend

=item 2/ A string to be passed to cpp, ex: '-DDEBUG'

=item 3/ A boolean indicating if the system include files should be included in the result (anything under /usr/)

=item 4/ a sub reference to be called everytime a node is added (see I<depender.pl> for an example)

=item 5/ A boolean indicating if the output of B<cpp> should be dumped on screen

=back

=head2 EXPORT

None .

=head1 DEPENDENCIES

B<cpp> must be in your execution path.

I<depender.pl> depends on B<Data::TreeDumper> to dump the dependency tree and B<PBS> if a graph is to
be generated.

=head1 AUTHOR

Nadim ibn Hamouda el Khemir <nadim@khemir.net>

=head1 SEE ALSO

B<PBS>: the Perl Build System from which B<Devel::Depend::Cpp> was extracted. Contact the author
for more information about B<PBS>.

=cut
