#!/usr/bin/perl

## AUTHORS:
##
## Original code by A. Chatzichristophi as Read_xml_v02.pl
## Edited by Vasilis J Promponas
##
## Contact: promponas.vasieleios [ay] ucy.ac.cytosolic
##          agathangelos.chatzichristofi [at] gmail.com

## PURPOSE AND USAGE
##
## This perl program reads a file residing in the working directory 
## named 'pmc_result.xml', which contains full text of a query against
## PubMed Central (PMC). The assumption is that the file contains 
## PMC entries related to autophagy. The objective of the program is
## to identify documents containing snippets of text that could be describing
## interactions of LIR motifs with Atg8 proteins. Snippets of text along
## with paper identification information and snippet location are written in 
## the tabular file 'xml_analysis.txt' which is then amenable to downstream 
## analysis (machine readable) and/or be loaded to a spreadsheet application
## for manual inspection.
##
## The code applies heuristic rules, derived from manual inspection of a few 
## thousands of papers curated by the LIRcentral database curators and dozens
## of trial-error experiments. 
## 
## This tools was instrumental in the initial steps of the LIRcentral database 
## curation process (see https://lircentral.eu) and is used to collect literature
## for major updates of LIRcentral.
##

use strict;
use warnings;
use diagnostics;
use XML::LibXML;

my $newfile;
my $outfile="xml_analysis.txt";

open ($newfile, '>', $outfile) or die "Den mpori na apothikefthi to arxio.";

binmode($newfile, ":utf8"); #To xrisimopio gia na mi vgazi minima gia ta unicodes.
binmode(STDOUT, ":utf8");

	my $filename = 'pmc_result.xml';
	
	my $doc = XML::LibXML->load_xml(location => $filename, no_blanks => 1);

	
	my $article_path = '//article'; 										# The path of each individual article.
	my $article_title_path = '//article-meta/title-group/article-title';	# The path of each individual article title.
	my $abstract_path = '//abstract/p'; 									# The path of each individual article abstract.
	my $body_path = '//body';												# The path of each individual article body-text..
	
	my $root = $doc->getDocumentElement;

my @articles = $root->findnodes($article_path); 							# Save articles as list items - WARNING - this can require a lot of RAM

my @single_article=();

for (my $i=0; $i<scalar @articles; $i++) 
{
	my $strings = XML::LibXML->load_xml( string => $articles[$i] );			# List to string
	my $title = $strings->findnodes($article_title_path);					# Get next article title
		#push @single_article, $title;	
		print $newfile "Article title: ", $title, "\n";
		print $newfile "-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-", "\n";
	my $abstract = $strings->findnodes($abstract_path);						# Then fetch the abstract ...
		#push @single_article, $abstract;
		#print $abstract, "\n","\n";
	my $body = $strings->findnodes($body_path);								# And the body-text
		#push @single_article, $body;	
		#print $body, "\n","\n";

#---------FINDING LIR PHRASES IN ABSTRACT -----------------------------------------------------------------------
	my @LIR_LC3 = ('LIR', '(LC3.{0,}interact.{0,}region)', 'AIM', '(Atg8.{0,}interact.{0,}motif)', '(LRS)', '(LC3.{0,}recognition.{0,}sequence)', '(xLIR)', '(x-LIR)', '(extended.{0,}LIR)',				
				'(microtubule.{0,}associated.{0,}protein)',	'(ATG8)', '(LC3)', '(light.{0,}chain.{0,}3)', '(GABARAP)', '(c.{0,}amino.{0,}butyric.{0,}acid)', '(γ.{0,}amino.{0,}butyric.{0,}acid)',  
				'(LDS)', '(LIR.{0,}docking.{0,}site)', '(LGG)');

	my @finding_words = ('conclude', 'confirm', 'demonstrate', 'determine', 'focus', 'found', 'identified', 'identify', 'indicat', 'report', 'revealed', 'show', 'suggest', 'summarize', 
						'validated', 'investigate');

	my @sentences = ('abolish', 'abolished', 'activity', 'adjacent', 'aggregates', 'alignment', 'amino acids', 'analysis', 'approaches', 'autophagic', 'auto-phagic', 'autophagy', 'between', 'bind', 
					'cargo', 'completely', 'complex', 'conserv', 'contain', 'crucial', 'cytosolic', 'degradation', 'different', 'direct', 'domain', 'essential', 'fail', 'functional', 'hallmarks', 
					'hydrophobic', 'identificat', 'increase', 'indicat', 'induces', 'interact', 'interaction', 'interface', 'isoforms', 'known', 'ligand', 'list', 'logo', 'lost', 'machinery', 
					'macroautophagy', 'mapped', 'mediates', 'mitochondrial', 'motif', 'mutant', 'mutati', 'protein', 'putative', 'receptor', 'recogniz', 'recruited', 'reduced', 'region', 
					'relationships', 'required', 'residues', 'sequence', 'structural', 'structure', 'suggest', 'tail', 'technical', 'terminal', 'terminus', 'through', 'trigger', 'verified');

	my @abstract_lines = split (/\./, $abstract);		
	my @body_lines = split (/\./, $body);	
					
					
my %abstract_list_of_findings= ();

	for (my $t=0; $t<scalar @abstract_lines; $t++) 
	{
		for (my $p=0; $p<scalar @finding_words; $p++) 
		{
			if ($abstract_lines[$t] =~ /$finding_words[$p]/ig)
			{
				for (my $m=0; $m<scalar @LIR_LC3; $m++) 
				{
					if ($abstract_lines[$t] =~ /$LIR_LC3[$m]/ig)
					{
						my $sentences_count=0;
						my @keywords=();
						for (my $n=0; $n<scalar @sentences; $n++) 
						{
							if ($abstract_lines[$t] =~ /$sentences[$n]/ig)
							{
								$sentences_count=$sentences_count+1;
								push @keywords, $sentences[$n];
									if ($sentences_count > 0)
									{
										if (! exists ($abstract_list_of_findings{$abstract_lines[$t]}))
										{
											$abstract_list_of_findings{$abstract_lines[$t]} = $abstract_lines[$t];

											print $newfile "Condition: ", "\t",
											$finding_words[$p], ' / ', $LIR_LC3[$m], ' / ';
											for (my $q=0; $q<scalar @keywords; $q++)
											{
												print $newfile $keywords[$q], "\n";
											}											
											print $newfile "Sentence in abstract: ", "\t", $abstract_lines[$t], "\.", "\n", "\n";
											print "I found something...!\n";
										}
									}
							}
						}
					}
				}
			}
		}
	}

					
#---------FINDING LIR PHRASES IN BODY------------------------------------------------------------------
my %body_list_of_findings= ();

	for (my $t=0; $t<scalar @body_lines; $t++) 
	{
		for (my $p=0; $p<scalar @finding_words; $p++) 
		{
			if ($body_lines[$t] =~ /$finding_words[$p]/ig)
			{
				for (my $m=0; $m<scalar @LIR_LC3; $m++) 
				{
					if ($body_lines[$t] =~ /$LIR_LC3[$m]/ig)
					{
						my $sentences_count=0;
						my @keywords=();
						for (my $n=0; $n<scalar @sentences; $n++) 
						{
							if ($body_lines[$t] =~ /$sentences[$n]/ig)
							{
								$sentences_count=$sentences_count+1;
								push @keywords, $sentences[$n];
									if ($sentences_count > 0)
									{
										if (! exists ($abstract_list_of_findings{$body_lines[$t]}))
										{
											$abstract_list_of_findings{$body_lines[$t]} = $body_lines[$t];

											print $newfile "Condition: ", "\t",
											$finding_words[$p], ' / ', $LIR_LC3[$m], ' / ';
											for (my $q=0; $q<scalar @keywords; $q++)
											{
												print $newfile $keywords[$q], "\n";
											}											
											print $newfile "Sentence in body: ", "\t", $body_lines[$t], "\.", "\n", "\n";
											print "I found something...!\n";
										}
									}
							}
						}
					}
				}
			}
		}
	}
		
#---------FINDING LIR MOTIFS---------------------------------------------------------------------------
		
	while($title =~ /([WFY][\-]{0,}[ARNDCEQGHILKMFPSTWYV][\-]{0,}[ARNDCEQGHILKMFPSTWYV][\-]{0,}[ILV])/g)
		{
			print $newfile "In title: ", "\t";
			print $newfile "$1\t" , "\n";
		}	
		
	for (my $k=0; $k<scalar @abstract_lines; $k++) 
	{
		while($abstract_lines[$k] =~ /([WFY][\-]{0,}[ARNDCEQGHILKMFPSTWYV][\-]{0,}[ARNDCEQGHILKMFPSTWYV][\-]{0,}[ILV])/g)
		{
			print $newfile "In abstract: ", "\t";
			print $newfile "$1\t", ": ", "$abstract_lines[$k]", "\n";
			#print "I found LIR motif!\n";
		}
	}
			
	for (my $k=0; $k<scalar @body_lines; $k++) 
	{
		while($body_lines[$k] =~ /([WFY][\-]{0,}[ARNDCEQGHILKMFPSTWYV][\-]{0,}[ARNDCEQGHILKMFPSTWYV][\-]{0,}[ILV])/g)
		{
			print $newfile "In body: ", "\t";
			print $newfile "$1\t", ": ", "$body_lines[$k]", "\n";
			#print "I found LIR motif!\n";
		}
	}	
	print $newfile "\n\t\t\t\t|-|-|-|-|-|-|-|-|-\t\t\t\t\n";
	
#---------\FNDING LIR MOTIFS---------------------------------------------------------------------------
	
}

my @lines=();

close $newfile;
