package panzhong_yx20160427;
use Exporter;
our @ISA=qw(Exporter);
our @EXPORT=qw(get_sub_list);

### mysql 
push @EXPORT, qw(mysql_input_autohead mysql_input_bed mysql_input_table mysql_output_table mysql_output_table_with_head isnumeric check_sql_log);
### time
push @EXPORT, qw(gettime get_day time_interval);
### fasta  targetscan
push @EXPORT, qw(fasta_out fa_out anti_reverse circRNA_forTargetScan_out get_targetscan_format 
get_sub_fasta get_circRNA_sequence_forTargetScan get_fasta_length fastafrombed12 bed12_treat join_bed12);
### circRNA analysis and report
push @EXPORT, qw(read_database_file calculate_md5 re_annotation_circRNA 
get_circRNA_bed12 drop_table_annotation_new_circRNA  bowtie2_rRNA get_circRNA_expression_dcc);
push @EXPORT, qw(add_column delete_column read_config get_taxid get_expression_all_txt get_md5_files);
push @EXPORT, qw(hash_md5_perl get_differentially_expressed_circRNA_list two_excel_writer txt2xlsx);
push @EXPORT, qw(read_bowtie2_log_new read_star_log read_file_type);

push @EXPORT, qw(calculate_q30 collect_md5 cutadaptor_multiplex_cpu fq_title_replace_multiplex_cpu fq_title_replace_perl get_length_distribution_plot);
push @EXPORT, qw(get_line_count gzip_fq_files gzip_fq_files_multiplex_cpu inference_cutadapt plot_histgram_R q30_multiplex_cpu q30_perl rename_fq_files);
push @EXPORT, qw(rm_fq_files run_cutadapt run_fq_title_replace_perl uncompress uncompress_multiplex_cpu waitquit);
push @EXPORT, qw(get_raw_reads_number get_q30_number get_rRNA_ratio_number get_mapped_number get_clean_reads_number get_nohup_time get_duplicate_number);
push @EXPORT, qw(fastqc_multiplex_cpu fastqc fastq_screen_multiplex_cpu fastq_screen head_multiplex_cpu head_fastq get_circRNA_statistics_dcc get_circRNA_statistics_dcc_prepare get_raw_line_count);
### edgeR
push @EXPORT, qw(get_column_index edgeR_de_table get_comparisons create_profiling_design_file create_2_sample_comparison_design_file create_unpaired_group_comparison_design_file create_paired_group_comparison_design_file edgeR_1sample_vs_group_comparison_fun edgeR_2sample_comparison_fun edgeR_logcpm edgeR_glm_qlf_fun edgeR_glm_lr_fun edgeR_glm_lr_paired_fun edgeR_classic_fun Rtable_add_head);
push @EXPORT, qw(get_edgeR_de_report edger_heatmap average_array edger_volcano_plot obtain_edgeR_volcano_data obtain_boxplot_data edger_boxplot edger_violin_plot ggplot2_violin ggplot2_boxplot edger_de_excel edgeR_profiling_excel get_junction_reads_from_expression);

use DBI;
use Cwd;
use File::Basename;
use Time::Local;
use Digest::MD5;
use File::Copy;
use strict;
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseXLSX;
use Excel::Writer::XLSX;
use List::Util qw{ sum };

my $perl510='perl';
my $myperl_dir='/workplace/software/myperl';
my $find_circ_dir="/workplace/software/find_circ-1.2";
my $database_file='/workplace/database/database_information.txt';
my $scatter_py="scatterplot20170308_pz.py";
my $volcano_py="VolcanoPlot_pz.py";
my $R_dir="/workplace/software/R/R-3.3.1/bin";


my ($mysqlserver,$mysqluser,$mysqlpw);
my $server ='yx';    #### yx kc
if($server eq 'yx')
{
     $mysqlserver='localhost';
     $mysqluser='pz';
     $mysqlpw='123456';
}
else
{
     $mysqlserver='192.168.0.211';
     $mysqluser='root';   $mysqlpw='123456';
}
my $database = 'panzhong';
my $use_pw=1;            ### confugure how to access mysql
=pod
          $cmd ="mysql -h$mysqlserver -u$mysqluser -p$mysqlpw <annotation_new_circRNA.sql";
          $cmd ="mysql -h$mysqlserver <annotation_new_circRNA.sql";
=cut

sub get_sub_list
{
  if($_[0] eq "--help")
  {
     print "\&get_sub_list(file1 -anh file2 -bnh -cnh -dwww -pwww)\n";

     print "    -anh\n";
     print "        n >= 0 : represents the key column of file1, 0-based.\n";
     print "        /h/    : file1 has head, otherwise file1 doesn't have head.\n\n";
     print "    -bnh is similar to a1 to config file2\n\n";
     print "    -cnh like nh\n";
     print "        n>0       : output the complement file, otherwise only output the sublist file.\n";
     print "        c1 =~ /h/ : output file should have head from file2.\n";
     print "        c1 =~ /m/ : output the losted element in file1.\n\n";
     print "    -pwww is the postfix of output file name. Default \"_contain_list\".\n\n";
     print "    -dwww is the output file name. if -d is on, -p is masked.\n";
     print "Example\n\n    \&get_sub_list(\$file1,\"-a0h\",\$file2,\"-b5h\",\"1mh\",\"-pannotation\")\n";
     print "    \&get_sub_list(\$file1,\"-a0h\",\$file2,\"-b5h\",\"-c1mh\",\"-pannotation\")\n\n";
  }
  else
  {
        my $input1="";
        my $input2="";
        my $para1="0";
        my $para2="0";
        my $para3="0";
        my $para4="_contain_list";
        my $para5="";

        my $num = @_;
        my $tag = 0;

        if($num < 2)
        {
               print "the input parameters is too little!\nPlease refer the help below:\n\n";
               &get_sub_list("--help");
               return;
        }
        else
        {
               $tag++;
        }

        my $j;
         for(my $i=0;$i < @_;$i++)
            {
               if(-e "$_[$i]")
               {
                   $input1=$_[$i];
                   $j= $i+1;
                   last;
               }
            }
         for(my $i=$j; $i < @_; $i++)
            {
            # print "$i\n";
                if(-e "$_[$i]")
               {
                   $input2=$_[$i];
                   last;
               }
            }

         unless($input1 && $input2)
           {
                print "can\'t find two exist files!\nPlease refer the help below:\n\n";
                &get_sub_list("--help");
                return;
           }

            for(my $i=0;$i<@_;$i++)
            {
               if($_[$i] =~ /\-a/)
               {
                   $para1=$_[$i];
               }
               elsif($_[$i] =~ /\-b/)
               {
                    $para2=$_[$i];
               }
               elsif($_[$i] =~ /\-c/)
               {
                    $para3=$_[$i];
               }
               elsif($_[$i] =~ /\-d/)
               {
                     $para5=$_[$i];
               }
               elsif($_[$i] =~ /\-p/)
               {
                      $para4=$_[$i];
               }
            }


        if($tag)
        {
          my $col1=0;
          my $col2=0;
          my $complement=0;

                     if( $para1 =~ /\d+/)
                     {
                       $col1 = $&;
                     }
                     if($para2 =~ /\d+/)
                     {
                       $col2 =$&;
                     }
                     if( $para3 =~ /\d+/)
                     {
                       $complement = $&;
                     }

                     my $output1;
                     my $output;

                         if($input1 =~ /\.\w+$/)
                         {
                            $output1 =$`.$para4;
                         }

                     if($para5)
                     {
                         $output = $para5;
                     }
                     else
                     {
                         $output = $output1.".txt";
                     }
                open (TOTAL, "$input2") or die "error(input2):$!";
                open (LIST, "$input1") or die "error(input2):$!";
                open (CONTAIN, ">$output") or die "error (output1):$!";

                if($complement)
                {
                            open (UNIQ, ">$output1\_complement_list.txt") or die "error(input2):$!";
                }
                 if($para3 =~ /m/)
                {
                            open (MISS, ">$output1\_miss.txt") or die "error(input2):$!";
                }

                my %sublist = ();
                my $line;
                while ( $line= <LIST>)
                {     chomp $line;
					 $line=~ s/[\r\n]//g;
                      my @name = split(/\t/,$line);
                      my $name = $name[$col1];
                         $sublist{$name} = 1;
                }

                my $count = keys(%sublist);
                my %gotlist = ();
                while ( $line= <TOTAL> )
                {

                  if( $line =~ /^\#/)
                   {  print "$line";   }
                   else
                   {    my $name = "KKKKKKK";
                        my @terms = split(/\t/, $line);
                        $name = $terms[$col2];
                        chomp $name;
                         $name=~ s/[\r\n]//g;
                       	if ( exists($sublist{$name}))
                        {
                           $gotlist{$name} = 1;
                           print CONTAIN "$line";
                          }
                         else
                         {
                           if($complement)
                           {
                              print  UNIQ "$line";
                           }
                         }
                    }

                }



                my $count1 = keys %gotlist;
                print "there are $count unique records in the list file!\n";
                print "there are $count1 unique records in the gotlist file!\n";


                if($para3 =~ /m/)
                {
                    my $m=0;
                      foreach(keys %sublist)
                     {
                          my $tag = $_;
                            if(not exists($gotlist{$tag}))
                              {
                                $m++;
                                print MISS "$tag","\n";
                              }
                     }
                     print "$m records are not found in the target file!\n";
                }

                close TOTAL;
                close LIST;
                close CONTAIN;
                if($para3 =~ /m/)
                {
                 close MISS;
                }
                if($complement)
                {
                   close UNIQ;
                }
        }### if num == 2
  }##if else --help
  1;
}##sub
                  # &read_star_log("$mydir/$file/${file}Log.final.out");
sub read_star_log
{
	my $file = shift;
	open (INPUT, "$file") or die "error(can't open $file):$!";
                  my $line;
                  my @array=();
                  while($line=<INPUT>)
                  {
                            if($line =~ /Number of input reads/)
                            {
                                   $line =~ /(\d+)/; push @array, $1;
						     }
						     elsif($line =~ /Uniquely mapped reads number/)
                            {
                                   $line =~ /(\d+)/; push @array, $1;
						     }
						     elsif($line =~ /Number of reads mapped to multiple loci/)
                            {
                                   $line =~ /(\d+)/; push @array, $1;
						     }
						     elsif($line =~ /Number of reads mapped to too many loci/)
                            {
                                   $line =~ /(\d+)/; push @array, $1;
						     }
						     elsif($line =~ /Number of chimeric reads/)
                            {
                                   $line =~ /(\d+)/; push @array, $1;
						     }
			       }
       close INPUT;
       return(\@array);  ###(total uniquely_mapped multi_mapped1 multi_mapped2 chimeric_reads)
}

###(total c0 c1 cm d1 s0 s1 sm rate)
sub read_bowtie2_log_new
{
	my $file = shift;
	open (INPUT, "$file") or die "error(can't open $file):$!";
                  my $line;
                  my @array=();
                  while($line=<INPUT>)
                  {
                            if($line =~ /^(\d+) reads\; of these\:/)
                                {
                                        my $reads_count=$1;
                                        push @array, $1;
                                        # print "\t\t\treads_count:$reads_count\n";
                                       while($line = <INPUT>)
                                       {
                                          if($line =~ /\s+([\d]+)\s+\([\d\.]+\%\)\s+aligned concordantly 0 times/)
                                          {
                                                push @array, $1;
                                          }
                                          elsif($line =~ /\s+([\d]+)\s+\([\d\.]+\%\)\s+aligned concordantly exactly 1 time/)
                                          {
                                               push @array, $1;
                                          }
                                          elsif($line =~ /\s+([\d]+)\s+\([\d\.]+\%\)\s+aligned concordantly >1 times/)
                                          {
                                               push @array, $1;
                                          }
                                          elsif($line =~ /\s+([\d]+)\s+\([\d\.]+\%\)\s+aligned discordantly 1 time/)
                                          {
                                               push @array, $1;
                                          }
                                          elsif($line =~ /\s+([\d]+)\s+\([\d\.]+\%\)\s+aligned 0 times/)
                                          {
                                               push @array, $1;
                                          }
                                          elsif($line =~ /\s+([\d]+)\s+\([\d\.]+\%\)\s+aligned exactly 1 time/)
                                          {
                                               push @array, $1;
                                          }
                                          elsif($line =~ /\s+([\d]+)\s+\([\d\.]+\%\)\s+aligned >1 times/)
                                          {
                                               push @array, $1;
                                          }
                                          elsif($line =~ /^([\d\.]+)\% overall alignment rate/)
                                          {
                                               push @array, $1;
                                           }
                                       }
                                }
			       }
       close INPUT;
       return(\@array);  ###PE(total c0 c1 cm d1 s0 s1 sm rate)  ###SE(total unmpped mapped1 mapped2 rate)
}


sub read_database_file
{
     print "\t\t\tReading Organism parametres.......................\n";
     my $org=shift;
     my $ref;
        open(PARAMETRES, "$database_file") or die "error (can't open $database_file):$!";
        my $line;
       OUTER: while($line=<PARAMETRES>)
        {
            if($line =~ /^\[(.*)\]/)
            {
              my $org_below = $1;
                 if(lc($org) eq lc($org_below))
                 {
                     # print "$org_below\n";
                     while($line=<PARAMETRES>)
                     {
                         if($line =~ /^\[/)
                         {
                            redo OUTER;
                         }
                         elsif($line =~ /^\s*\$(.+)\=\s*[\'\"](.+)[\'\"]\;/)
                         {
                            # print "$line\n";
                            my ($p1,$p2)=($1,$2);
                            # print "$p1\t$p2\n";
                            $ref->{$org}->{$p1}=$p2;
                         }
                     }
                 }
            }
        }
        close PARAMETRES;
        return($ref);
}

sub gettime {

my ($sec, $min,$hour,$mday, $mon, $year) = localtime(time);
# ($sec, $min, $hour, $mday, $mon, $year,undef,undef,undef) = localtime(time);
# $year += 1900;
# $mon  = sprintf("%02d", $mon+1);
    # printf ("%02d:%02d:%02d:%02d\n", $mday,$hour,$min,$sec);
    $mon++;
    my $time= sprintf("%02d:%02d:%02d:%02d:%02d:%02d\n", $year,$mon,$mday,$hour,$min,$sec);
    return($time);
}
sub time_interval
{
     my ($time1,$time2)=@_;
     my @time=split(/:/,$time1);
     my $s1 = timelocal($time[5],$time[4],$time[3],$time[2],$time[1]-1,$time[0]);
        @time=split(/:/,$time2);
     my $s2 = timelocal($time[5],$time[4],$time[3],$time[2],$time[1]-1,$time[0]);
     my $s = abs($s1 - $s2);
     if($s>=86400)
     {
         my $day = int($s/86400);
         my $hour = int(($s-$day*86400)/3600);
         my $minut = int(($s-$day*86400-$hour*3600)/60);
         return("$day:$hour:$minut");
     }
     elsif($s>=3600)
     {
         my $hour = int($s/3600);
         my $minut = int(($s-$hour*3600)/60);
         return("$hour:$minut");
     }
     else
     {
         my $minut = int($s/60);
         return("$minut");
     }
}






sub get_day
{
 my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
   $year += 1900;
   $mon++;

   if($mon<10)
   {
     $mon='0'.$mon;
    }
   if($mday<10)
   {
     $mday='0'.$mday;
   }
   my $num = $year.$mon.$mday;
   return($num);
}


sub calculate_md5
{
	 my ($data_dir,$myperl_dir,$mydir)=@_;
   chdir($data_dir);
   unless(-f "$data_dir/md5.fastq.txt")
   {
       copy("$myperl_dir/hhash.py","$data_dir/hhash.py");
       my $cmd ="python hhash.py";
       print "$cmd\n"; system($cmd);
   }
   chdir($mydir);
}
sub re_annotation_circRNA
{
              my ($projectid,$transcriptome,$total,$genome,$method)=@_;
              
             $transcriptome =~ /(\w+)\.(\w+)/;
             my ($transcriptome_database,$poss_inf)=($1,$2);

             print "annotation start: ", &gettime;
                          &annotation_new_circRNA($transcriptome_database,"$projectid\_CircRNAs",$transcriptome,$total);                          
             print "annotation complete: ",&gettime;

             unless(-f "$poss_inf.txt")
             {
                          &mysql_output_table($transcriptome_database,$poss_inf,$poss_inf);
             }
             my $bedhead = "track name=\'$projectid\' description=\'$projectid\' itemRgb=On color=0,60,120 useScore=1";
             $bedhead = "track name=\'$projectid\_$method\' description=\'$projectid\_$method\' itemRgb=On color=0,60,120 useScore=1",if($method);
             
             &get_circRNA_bed12("$projectid\_CircRNAs_best_transcript",$poss_inf,$bedhead);
             &fastafrombed12("$projectid\_CircRNAs_best_transcript",$genome);
             rename "$projectid\_CircRNAs_best_transcript.fa","$projectid\_CircRNAs.fa";
             rename "$projectid\_CircRNAs_best_transcript.bed","$projectid\_CircRNAs_UCSC.bed";
             print &gettime;
             print "\n\n...annotation_new_circRNA excuted!\n";
}


sub annotation_new_circRNA
{
         my($database,$table,$transcriptome,$total)=@_;
         &mysql_input_bed($database,$table,$table,6);
         print "input bed $table.bed\n";
         &drop_table_annotation_new_circRNA($database,$table,1);
         open FILE1, ">annotation_new_circRNA.sql";
         print FILE1 "
         use $database\;
         alter table $table add index coordinates(chrom, txStart, txEnd, strand)\;
         CREATE TABLE $table\_known
         select distinct A.*,B.circRNA_ID,B.circRNA,B.source
         from $table as A left join $total as B
         on A.chrom=B.chrom and A.txStart=B.txStart and A.txEnd=B.txEnd and A.strand=B.strand
         where B.chrom is not null
         union
         select distinct A.*,B.circRNA_ID,B.circRNA,B.source
         from $table as A, $total as B
         where A.chrom=B.chrom and A.txStart=B.txStart and A.txEnd=B.txEnd and A.strand='*'\;
         ALTER TABLE $table\_known ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_known ADD INDEX name(name);
         CREATE TABLE $table\_novo
         select distinct A.*
         from $table as A left join $table\_known as B
         on A.name=B.name
         where B.name is null\;
         ALTER TABLE $table\_novo ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo ADD INDEX name(name);

CREATE TABLE $table\_novo_intragenic
select distinct A.chrom,A.txStart,A.txEnd,A.strand,A.name,B.transID as overlap_transID,B.name as overlap_name,B.GeneName as overlap_genename,B.sourceID,B.source
from $table\_novo as A, $transcriptome as B
where A.chrom=B.chrom and A.txStart<B.txEnd and A.txEnd>B.txStart
\;
         ALTER TABLE $table\_novo_intragenic ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_intragenic ADD INDEX name(name);
         ALTER TABLE $table\_novo_intragenic ADD INDEX overlap_transID(overlap_transID);
CREATE TABLE $table\_novo_intergenic
select distinct A.*
from $table\_novo as A left join $table\_novo\_intragenic as B
on A.name=B.name
where B.name is null
\;
         ALTER TABLE $table\_novo_intergenic ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_intergenic ADD INDEX name(name);
CREATE TABLE $table\_novo_exonic_temp1
select distinct A.*,B.name as overlap_exonname
from $table\_novo\_intragenic as A, $transcriptome\_exons_target as B
where A.overlap_transID=B.transID and A.strand=B.strand and A.chrom=B.chrom and A.txStart=B.txStart
union
select distinct A.*,B.name as overlap_exonname
from $table\_novo\_intragenic as A, $transcriptome\_exons_target as B
where A.overlap_transID=B.transID and A.chrom=B.chrom and A.txStart=B.txStart and A.strand='*'
\;
         ALTER TABLE $table\_novo_exonic_temp1 ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_exonic_temp1 ADD INDEX name(name);
         ALTER TABLE $table\_novo_exonic_temp1 ADD INDEX overlap_transID(overlap_transID);
         ALTER TABLE $table\_novo_exonic_temp1 ADD INDEX overlap_exonname(overlap_exonname);
CREATE TABLE $table\_novo_exonic
select distinct A.*
from $table\_novo\_exonic_temp1 as A, $transcriptome\_exons_target as B
where A.overlap_transID=B.transID and A.strand=B.strand and A.chrom=B.chrom and A.txEnd=B.txEnd
union
select distinct A.*
from $table\_novo\_exonic_temp1 as A, $transcriptome\_exons_target as B
where A.overlap_transID=B.transID and A.chrom=B.chrom and A.txEnd=B.txEnd and A.strand='*'
\;
         ALTER TABLE $table\_novo_exonic ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_exonic ADD INDEX name(name);
         ALTER TABLE $table\_novo_exonic ADD INDEX overlap_transID(overlap_transID);
         ALTER TABLE $table\_novo_exonic ADD INDEX overlap_exonname(overlap_exonname);

CREATE TABLE $table\_novo\_intragenic_non_exonic
select distinct A.*
from $table\_novo\_intragenic as A left join  $table\_novo\_exonic as B
on A.name=B.name
where B.name is null
\;
         ALTER TABLE $table\_novo_intragenic_non_exonic ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_intragenic_non_exonic ADD INDEX name(name);
         ALTER TABLE $table\_novo_intragenic_non_exonic ADD INDEX overlap_transID(overlap_transID);

CREATE TABLE $table\_novo_intronic
select distinct A.*
from $table\_novo\_intragenic_non_exonic as A, $transcriptome\_normal_junctions_target_min as B
where A.overlap_transID=B.transID and A.strand=B.strand and A.txStart>=B.txStart and A.txEnd<=B.txEnd
union
select distinct A.*
from $table\_novo\_intragenic_non_exonic as A, $transcriptome\_normal_junctions_target_min as B
where A.overlap_transID=B.transID and A.txStart>=B.txStart and A.txEnd<=B.txEnd and A.strand='*'
\;
         ALTER TABLE $table\_novo_intronic ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_intronic ADD INDEX name(name);
         ALTER TABLE $table\_novo_intronic ADD INDEX overlap_transID(overlap_transID);

CREATE TABLE $table\_novo_intragenic_nonciRNA
select distinct A.*
from $table\_novo\_intragenic_non_exonic as A left join $table\_novo\_intronic as B
on A.name=B.name
where B.name is null
\;
         ALTER TABLE $table\_novo_intragenic_nonciRNA ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_intragenic_nonciRNA ADD INDEX name(name);
         ALTER TABLE $table\_novo_intragenic_nonciRNA ADD INDEX overlap_transID(overlap_transID);

CREATE TABLE $table\_novo_intragenic_nonciRNA_sense
select distinct A.*
from $table\_novo\_intragenic_nonciRNA as A, $transcriptome as B
where A.overlap_transID=B.transID and A.txStart<B.txEnd and A.txEnd>B.txStart and A.strand=B.strand
union
select distinct A.*
from $table\_novo\_intragenic_nonciRNA as A, $transcriptome as B
where A.overlap_transID=B.transID and A.txStart<B.txEnd and A.txEnd>B.txStart and A.strand='*'
\;
         ALTER TABLE $table\_novo_intragenic_nonciRNA_sense ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_intragenic_nonciRNA_sense ADD INDEX name(name);
         ALTER TABLE $table\_novo_intragenic_nonciRNA_sense ADD INDEX overlap_transID(overlap_transID);

CREATE TABLE $table\_novo_antisense
select distinct A.*
from $table\_novo\_intragenic_nonciRNA as A left join $table\_novo\_intragenic_nonciRNA_sense as B
on A.name=B.name
where B.name is null
\;
         ALTER TABLE $table\_novo_antisense ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_antisense ADD INDEX name(name);
         ALTER TABLE $table\_novo_antisense ADD INDEX overlap_transID(overlap_transID);

CREATE TABLE $table\_novo_exonic_single
select distinct A.*
from $table\_novo\_exonic_temp1 as A, $transcriptome\_exons_target as B
where A.overlap_transID=B.transID and A.strand=B.strand and A.txEnd=B.txEnd
and A.overlap_exonname=B.name
union
select distinct A.*
from $table\_novo\_exonic_temp1 as A, $transcriptome\_exons_target as B
where A.overlap_transID=B.transID and A.txEnd=B.txEnd and A.strand='*'
and A.overlap_exonname=B.name
\;
         ALTER TABLE $table\_novo_exonic_single ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_exonic_single ADD INDEX name(name);
         ALTER TABLE $table\_novo_exonic_single ADD INDEX overlap_transID(overlap_transID);
         ALTER TABLE $table\_novo_exonic_single ADD INDEX overlap_exonname(overlap_exonname);

CREATE TABLE $table\_novo_exonic_multi
select distinct A.*
from $table\_novo\_exonic_temp1 as A left join $table\_novo\_exonic_single as B
on A.name=B.name and A.overlap_transID=B.overlap_transID
where B.name is null
\;
         ALTER TABLE $table\_novo_exonic_multi ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_exonic_multi ADD INDEX name(name);
         ALTER TABLE $table\_novo_exonic_multi ADD INDEX overlap_transID(overlap_transID);
         ALTER TABLE $table\_novo_exonic_multi ADD INDEX overlap_exonname(overlap_exonname);

CREATE TABLE $table\_novo_junction_target
select distinct A.chrom,A.txStart,A.txEnd,A.name,1000 as score,A.strand,
(B.txEnd-B.txStart) as left_exon,(C.txEnd-C.txStart) as right_exon,
A.overlap_transID as transID,A.overlap_name as Accession,A.overlap_genename as GeneName,'exonic' as Catalog
from $table\_novo\_exonic_multi as A join $transcriptome\_exons_target as B
on A.overlap_transID=B.transID and A.txStart=B.txStart
join $transcriptome\_exons_target as C
on A.overlap_transID=C.transID and A.txEnd=C.txEnd
union
select distinct A.chrom,A.txStart,A.txEnd,A.name,900,A.strand,
(txEnd-txStart)/2,txEnd-txStart-(txEnd-txStart)/2,A.overlap_transID as transID,A.overlap_name as Accession,A.overlap_genename as GeneName,'exonic'
from $table\_novo\_exonic_single as A
union
select distinct A.chrom,A.txStart,A.txEnd,A.name,500,A.strand,
(txEnd-txStart)/2,txEnd-txStart-(txEnd-txStart)/2,A.overlap_transID as transID,A.overlap_name as Accession,A.overlap_genename as GeneName,'intronic'
from $table\_novo\_intronic as A
union
select distinct A.chrom,A.txStart,A.txEnd,A.name,100,A.strand,
(txEnd-txStart)/2,txEnd-txStart-(txEnd-txStart)/2,A.overlap_transID as transID,A.overlap_name as Accession,A.overlap_genename as GeneName,'sense overlapping'
from $table\_novo\_intragenic_nonciRNA_sense as A
union
select distinct A.chrom,A.txStart,A.txEnd,A.name,100,A.strand,
(txEnd-txStart)/2,txEnd-txStart-(txEnd-txStart)/2,A.overlap_transID as transID,A.overlap_name as Accession,A.overlap_genename as GeneName,'antisense'
from $table\_novo\_antisense as A
union
select distinct A.chrom,A.txStart,A.txEnd,A.name,100,A.strand,
(txEnd-txStart)/2,txEnd-txStart-(txEnd-txStart)/2,null,null,null,'intergenic'
from $table\_novo\_intergenic as A
\;
         ALTER TABLE $table\_novo_junction_target ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_junction_target ADD INDEX name(name);
         ALTER TABLE $table\_novo_junction_target ADD INDEX transID(transID);

CREATE TABLE $table\_novo_junction_target_temp1
select distinct A.*,B.sourceID
from $table\_novo\_junction_target A, $transcriptome as B
where A.transID=B.transID
\;
         ALTER TABLE $table\_novo_junction_target_temp1 ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_junction_target_temp1 ADD INDEX name(name);
         ALTER TABLE $table\_novo_junction_target_temp1 ADD INDEX transID(transID);
         ALTER TABLE $table\_novo_junction_target_temp1 ADD INDEX sourceID(sourceID);

CREATE TABLE $table\_novo_junction_target_temp2
select distinct A.*
from $table\_novo\_junction_target_temp1 as A,(select distinct B.name,min(B.sourceID) as sourceID
from $table\_novo\_junction_target_temp1 as B group by B.name) as C
where A.name=C.name and A.sourceID=C.sourceID
\;

         ALTER TABLE $table\_novo_junction_target_temp2 ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_junction_target_temp2 ADD INDEX name(name);
         ALTER TABLE $table\_novo_junction_target_temp2 ADD INDEX transID(transID);
         ALTER TABLE $table\_novo_junction_target_temp2 ADD INDEX sourceID(sourceID);

CREATE TABLE $table\_novo\_junction_target_temp3
select distinct A.*
from $table\_novo\_junction_target_temp2 as A,(select distinct B.name,min(length(B.Accession)) as Acclength
from $table\_novo\_junction_target_temp2 as B group by B.name) as C
where A.name=C.name and length(A.Accession)=C.Acclength
\;
         ALTER TABLE $table\_novo_junction_target_temp3 ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_junction_target_temp3 ADD INDEX name(name);
         ALTER TABLE $table\_novo_junction_target_temp3 ADD INDEX transID(transID);
         ALTER TABLE $table\_novo_junction_target_temp3 ADD INDEX sourceID(sourceID);

CREATE TABLE $table\_novo\_junction_target_temp4
select distinct A.*
from $table\_novo\_junction_target_temp3 as A,(select distinct B.name,min(B.transID) as transID
from $table\_novo\_junction_target_temp3 as B group by B.name) as C
where A.name=C.name and A.transID=C.transID
\;
         ALTER TABLE $table\_novo_junction_target_temp4 ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_junction_target_temp4 ADD INDEX name(name);
         ALTER TABLE $table\_novo_junction_target_temp4 ADD INDEX transID(transID);
         ALTER TABLE $table\_novo_junction_target_temp4 ADD INDEX sourceID(sourceID);

CREATE TABLE $table\_novo_best_transcript
select distinct A.chrom,A.txStart,A.txEnd,A.name,A.score,A.strand,
A.left_exon,A.right_exon,A.transID,A.Accession,A.GeneName,A.Catalog
from $table\_novo\_junction_target_temp4 as A
union
select distinct A.*
from $table\_novo\_junction_target as A
where A.transID is null
\;
         ALTER TABLE $table\_novo_best_transcript ADD INDEX coordinates(chrom, txStart, txEnd, strand);
         ALTER TABLE $table\_novo_best_transcript ADD INDEX name(name);
         ALTER TABLE $table\_novo_best_transcript ADD INDEX transID(transID);

CREATE TABLE $table\_annotation
select distinct A.chrom,A.txStart,A.txEnd,A.name,A.score,A.strand,A.circRNA_ID as circBaseID,A.source,
B.Accession as best_transcript,B.GeneName,B.Catalog
from $table\_known as A, $total\_best_transcript as B
where A.circRNA=B.circRNA
union
select distinct A.chrom,A.txStart,A.txEnd,A.name,A.score,A.strand,null,null,
A.Accession as best_transcript,A.GeneName,A.Catalog
from $table\_novo_best_transcript as A
\;
update $table\_annotation
set source=\'novel\'
where source is null\;
CREATE TABLE $table\_best_transcript
select distinct A.chrom,A.txStart,A.txEnd,A.name,A.score,A.strand,B.left_exon,B.right_exon,B.transID,
B.Accession,B.GeneName,B.Catalog
from $table\_known as A, $total\_best_transcript as B
where A.circRNA=B.circRNA
union
select distinct A.*
from $table\_novo_best_transcript as A
\;
         ";
         close FILE1;
     my $cmd;
     if($use_pw)
     {
          $cmd ="mysql -h$mysqlserver -u$mysqluser -p$mysqlpw <annotation_new_circRNA.sql";
      }
     else
     {
          $cmd ="mysql -h$mysqlserver <annotation_new_circRNA.sql";
     }
 print "$cmd\n";
  system "$cmd"; #input_psl.sql�ļ�ֻ�ǽ�psl�ļ����뵽���С�
                 ##  unlink "annotation_new_circRNA.sql";
           &mysql_output_table_with_head($database,"$table\_annotation","$table\_annotation");
           &mysql_output_table($database,"$table\_best_transcript","$table\_best_transcript");
           &drop_table_annotation_new_circRNA($database,$table,0);
}

sub drop_table_annotation_new_circRNA
{
    my($database, $table,$tag)=@_;
           open FILE1, ">drop_table_annotation_new_circRNA.sql";
           print FILE1
           "
use $database;
DROP TABLE IF EXISTS \`$table\_known\`\;
DROP TABLE IF EXISTS \`$table\_novo\`\;
DROP TABLE IF EXISTS \`$table\_novo_intragenic\`\;
DROP TABLE IF EXISTS \`$table\_novo_intergenic\`\;
DROP TABLE IF EXISTS \`$table\_novo_exonic_temp1\`\;
DROP TABLE IF EXISTS \`$table\_novo_exonic\`\;
DROP TABLE IF EXISTS \`$table\_novo_intragenic_non_exonic\`\;
DROP TABLE IF EXISTS \`$table\_novo_intronic\`\;
DROP TABLE IF EXISTS \`$table\_novo_intragenic_nonciRNA\`\;
DROP TABLE IF EXISTS \`$table\_novo_intragenic_nonciRNA_sense\`\;
DROP TABLE IF EXISTS \`$table\_novo_antisense\`\;
DROP TABLE IF EXISTS \`$table\_novo_exonic_single\`\;
DROP TABLE IF EXISTS \`$table\_novo_exonic_multi\`\;
DROP TABLE IF EXISTS \`$table\_novo_junction_target\`\;
DROP TABLE IF EXISTS \`$table\_novo_junction_target_abparts\`\;
DROP TABLE IF EXISTS \`$table\_novo_junction_target_temp1\`\;
DROP TABLE IF EXISTS \`$table\_novo_junction_target_temp2\`\;
DROP TABLE IF EXISTS \`$table\_novo_junction_target_temp3\`\;
DROP TABLE IF EXISTS \`$table\_novo_junction_target_temp4\`\;
DROP TABLE IF EXISTS \`$table\_novo_best_transcript\`\;
";
if($tag)
{
    print FILE1 "
DROP TABLE IF EXISTS \`$table\_best_transcript\`\;
DROP TABLE IF EXISTS \`$table\_annotation\`\;
";
}
           close FILE1;
     my $cmd;
     if($use_pw)
     {
          $cmd ="mysql -h$mysqlserver -u$mysqluser -p$mysqlpw <drop_table_annotation_new_circRNA.sql";
      }
     else
     {
          $cmd ="mysql -h$mysqlserver <drop_table_annotation_new_circRNA.sql";
     }
 print "$cmd\n";
 system "$cmd"; 
     # unlink "drop_table_annotation_new_circRNA.sql";
}

                     ## &mysql_input_bed($database,$file,$table,$column);
sub mysql_input_bed
{
   my($database,$file,$table,$column)=@_;
   my @columns=qw(chrom txStart txEnd name score strand thickStart thickEnd itemRgb blockCount blockSizes blockStarts);
   my @types=split ' ', q/varchar(255) int(10) int(10) varchar(255) decimal(38,4) varchar(255) int(10) int(10) varchar(255) int(10) longtext longtext/;
   my @columns_use=@columns[0..$column-1];
   my @types_use=@types[0..$column-1];
   my $int=int(rand(100000000));
      $int += 1000000000;
      print "rename $file.bed bedtemp$int.txt\n";
      unless(-f "bedtemp$int.txt")
      {
           rename("$file.bed","bedtemp$int.txt");
	  }
	  else
	  {         
		   unlink("bedtemp$int.txt");
		   rename("$file.bed","bedtemp$int.txt");
		  }
   if(-f "bedtemp$int.txt")
   {
        &mysql_input_table($database,"bedtemp$int",$table,\@columns_use,\@types_use);
    }
    else
    {
		print "can't find bedtemp$int.txt\n";
		}
   rename("bedtemp$int.txt","$file.bed");
}
        #  mysql_input_table($database,$file,$table,\@columns,\@types);
sub mysql_input_autohead
{
open (INPUT, "$_[1].txt") or die "error(can't open $_[1].txt):$!";
open(OUTPUT, ">temp.txt") or die "error (can't create temp.txt):$!";
my $file=$_[1];
my $table;
if($_[2])
{
   $table=$_[2];
}
else
{
  $table=$file;
}
print "read the head:\n";
my $line = <INPUT>;
$line=~s/[\r\n]//g;
my @title = split(/\t/,$line);
my %title;
foreach (@title)
{
  s/[\+\*\#\[\]\-\(\)\{\}\?\<\>\,\;\:\"\']+/ /g;
  s/[\s\.]/_/g;

  my $t = $_;
     $t =~ s/[\w\d]+//g;
     if($t)
     {
           print "title is not good $t\n";
           return;
     }


  if(exists($title{$_}))
  {
    $_ .="_1";
    $title{$_}=1;
  }
  else
  {
    $title{$_}=1;
  }
}
my @type;
my @type_tag;

for(my $i=0;$i<@title;$i++)
   {
     $type_tag[$i]=1;   ###1 int 2 float 3 varchar255 4 varchar 8000
   }
print "determine the column :\n";
while($line=<INPUT>)
{
$line=~s/[\r\n]//g;
my @line = split(/\t/,$line);
   for(my $i=0;$i<@title;$i++)
   {
     if($line[$i])
     {
       if(length($line[$i]) > 255)
       {
        $type_tag[$i]=4;
        }
     }
     else
     {
      $line[$i]='';
     }

     if($line[$i] && $line[$i] =~ /\D/)
     {

       if(isnumeric($line[$i]))
       {
           $type_tag[$i]=2;
        }
       elsif($type_tag[$i] <3)
        {
          $type_tag[$i]=3;
        }
     }
   }
   $line = join("\t",@line[0..(@title-1)]);
print OUTPUT "$line\n";
}
close INPUT;
close OUTPUT;

for(my $i=0;$i<@title;$i++)
   {
     if($type_tag[$i] == 1)
     {
        $type[$i] = 'int(10) default \'0\'';
      }
     elsif($type_tag[$i] == 2)
     {
        $type[$i] = 'decimal(38,4) default \'0\'';
     }
     elsif($type_tag[$i] == 3)
     {
        $type[$i] = 'varchar(255) default \'\'';
     }
     elsif($type_tag[$i] == 4)
     {
        $type[$i] = 'longtext default \'\'';
     }
   }
for(my $i=0;$i<@title;$i++)
   {
#      $title[$i] .= " $type[$i] null";   ###1 int 2 float 3 varchar255 4 varchar 8000
   }
my $title = join(", ", @title);

open FILE1, ">mysql_input_autohead.sql";
print FILE1 "use $_[0]\;
DROP TABLE IF EXISTS \`$table\`\;
SET \@saved_cs_client     = \@\@character_set_client\;
SET character_set_client = utf8\;
CREATE TABLE \`$table\` (";
 for(my $i=0;$i<$#title;$i++)
 {
  print "$title[$i]\t$type[$i]\n";
  print FILE1 "\`$title[$i]\` $type[$i],\n";
 }
 print FILE1 "\`$title[-1]\` $type[-1]";
 print FILE1 ") ENGINE=innodb DEFAULT CHARSET=utf8;
SET character_set_client = \@saved_cs_client;
load data local infile \'$file.txt\' into table $table IGNORE 1 LINES;";
close FILE1;
  my $cmd;
     if($use_pw)
     {
          $cmd ="mysql -h$mysqlserver -u$mysqluser -p$mysqlpw <mysql_input_autohead.sql>mysql_input_autohead.log";
      }
     else
     {
          $cmd ="mysql -h$mysqlserver <mysql_input_autohead.sql>mysql_input_autohead.log";
     }
 print "$cmd\n";
 system "$cmd";
 check_sql_log("mysql_input_autohead.log");
# unlink "mysql_input_autohead.sql";
print "successfully input a table!\n";
}

sub check_sql_log
{
  my $log=shift;
  open(LOG, "<$log") or die "error (can't create $log):$!";	
  while(<LOG>)
  {
	  die("there is an error in the sql log file\n"),if(/error/);
	  }
  close LOG;	
}

sub isnumeric
{
    my $val = shift;
    return length( do { no warnings "numeric"; $val & "" } ) > 0;
}
         ##  &mysql_output_table_with_head($database,"$table\_annotation","$table\_annotation");
sub mysql_output_table_with_head
{
open(OUTPUT, ">$_[2].txt") or die "error (output1):$!";
my $dbh = DBI->connect("DBI:mysql:database=$_[0];host=$mysqlserver;",$mysqluser,$mysqlpw,{'RaiseError' => 1});
my $sqr = $dbh->prepare("SHOW COLUMNS FROM $_[1];");
   $sqr->execute();
   my @title;
   while(my @ref = $sqr->fetchrow_array())
           {
                push @title,$ref[0];
           }
   my $title = join("\t",@title);
   print OUTPUT "$title\n";

   $sqr = $dbh->prepare("SELECT * FROM $_[1]");
   $sqr->execute();
       while(my @ref = $sqr->fetchrow_array())
           {
                for(my $i=0;$i<@ref;$i++)
                {
                   unless(defined($ref[$i]))
                   {
                     $ref[$i]='';
                   }
                }
                my $line = join("\t",@ref);
                print OUTPUT "$line\n";
           }
close OUTPUT;
$dbh->disconnect;
}

sub mysql_output_table
{
open(OUTPUT, ">$_[2].txt") or die "error (output1):$!";
my $dbh = DBI->connect("DBI:mysql:database=$_[0];host=$mysqlserver;",$mysqluser,$mysqlpw,{'RaiseError' => 1});
my $sqr = $dbh->prepare("SELECT * FROM $_[1]");
 $sqr->execute();
       while(my @ref = $sqr->fetchrow_array())
           {
                for(my $i=0;$i<@ref;$i++)
                {
                   unless(defined($ref[$i]))
                   {
                     $ref[$i]='';
                   }
                }
                my $line = join("\t",@ref);
                print OUTPUT "$line\n";
           }
close OUTPUT;
$dbh->disconnect;
}
        #  mysql_input_table($database,$file,$table,\@columns,\@types);
sub mysql_input_table
{
my ($database,$file,$table,$columns_ref,$type_ref)=@_;
open(INPUT, "$file.txt") or die "error ($file.txt):$!";
open(OUTPUT, ">$file") or die "error ($file):$!";
while(my $line = <INPUT>)
{
                 $line=~s/[\r\n]//g;
                 my @terms = split(/\t/,$line);
                 my $out = join("\t",@terms);
                 print OUTPUT "$out\n";
}
close INPUT;
close OUTPUT;

open(OUTPUT, ">mysql_input_table.sql") or die "error (output1):$!";
print OUTPUT "use $database\;
DROP TABLE IF EXISTS \`$table\`\;
SET \@saved_cs_client     = \@\@character_set_client\;
SET character_set_client = utf8\;
CREATE TABLE \`$table\` (";
 for(my $i=0;$i<@{$columns_ref}-1;$i++)
 {
  print "$columns_ref->[$i]\t$type_ref->[$i]\n";
  print OUTPUT "\`$columns_ref->[$i]\` $type_ref->[$i],\n";
 }
  print "\`$columns_ref->[-1]\` $type_ref->[-1]\n";
 print OUTPUT "\`$columns_ref->[-1]\` $type_ref->[-1]";
 print OUTPUT ") ENGINE=innodb DEFAULT CHARSET=utf8;
SET character_set_client = \@saved_cs_client;
load data local infile \'$file\' into table $table;";
close OUTPUT;
    my $cmd;
     if($use_pw)
     {
          $cmd ="mysql --local-infile=1 -h$mysqlserver -u$mysqluser -p$mysqlpw <mysql_input_table.sql";
      }
     else
     {
          $cmd ="mysql --local-infile=1 -h$mysqlserver <mysql_input_table.sql";
     }
 print "$cmd\n";
 system "$cmd";
 # unlink "mysql_input_table.sql";
 unlink "$file";
}

sub fastafrombed12
{
      my ($bed,$genome_seq)=@_;
      &bed12_treat($bed);
      print "fastaFromBed -fi $genome_seq -bed $bed\_treated.bed -fo $bed\_treated.fa -name\n";
      system "fastaFromBed -fi $genome_seq -bed $bed\_treated.bed -fo $bed\_treated.fa -name";
      &join_bed12($bed);
        unlink "$bed\_treated.fa";
        unlink "$bed\_treated.bed";
}

sub bed12_treat
{
        my $bed=$_[0];
        my $line;
        open(INPUT, "$bed.bed") or die "error (input1):$!";
        open(OUTPUT, ">$bed\_treated.bed") or die "error (output1):$!";
        while($line=<INPUT>)
        {
          if($line !~ /^track/ && $line !~ /^\#/)
          {
             $line =~ s/\r\n//g;
             my @term = split(/\t/,$line);
             my ($chrom,$txstart, $txend,$name, $score,$strand,$thickstart,$thickend,$itemRgb,$blockCount,$blockSizes,$blockStarts) = @term;
             my @blockSizes=split(",",$blockSizes);
             my @blockStarts=split(",",$blockStarts);
                            for(my $i=0;$i<$blockCount;$i++)
                            {
                                my $exonname=$name."_exon$i";
                                my $exonstart=$txstart+$blockStarts[$i];
                                my $exonend=$txstart+$blockStarts[$i]+$blockSizes[$i];
                                print OUTPUT "$chrom\t$exonstart\t$exonend\t$exonname\t$score\t$strand\n";
                            }
           }
        }
        close OUTPUT;
        close INPUT;
}
sub join_bed12
{
        my $bed=$_[0];
        my $line;
        open(INPUT, "$bed.bed") or die "error ($bed.bed):$!";
        open(SEQ, "$bed\_treated.fa") or die "error ($bed\_treated.fa):$!";
        open(OUTPUT, ">$bed.fa") or die "error ($bed.fa):$!";
        my %sequence;
        while(my $line = <SEQ>)
        {
                $line =~ />(.+)\n/;
                my $seq = $1;
                $line = <SEQ>;
                $line=~s/[\r\n]//g;
                $sequence{$seq}=$line;
                # print "$sequence{$seq}\n";
        }
        while($line=<INPUT>)
        {
          if($line !~ /^track/ && $line !~ /^\#/)
          {
             $line =~ s/\r\n//g;
             my @term = split(/\t/,$line);
             my ($chrom,$txstart, $txend,$name, $score,$strand,$thickstart,$thickend,$itemRgb,$blockCount,$blockSizes,$blockStarts) = @term;
             my $seq="";
                           for(my $i=0;$i<$blockCount;$i++)
                            {
                                my $exonname=$name."_exon$i";
                                   $seq.=$sequence{$exonname};
                            }
                           if($strand eq '-')
                           {
                            $seq=anti_reverse($seq);
                            }
                            $seq=&fasta_out($seq);
            if($name && $seq)
             {
                  print OUTPUT ">$name\n$seq";
             }
          }
         }
        close INPUT;
        close SEQ;
        close OUTPUT;
}

sub fasta_out
{
              my $j=0;
	      my $temp = $_[0];
              $temp =~ s/\W//g;
              my $fasta = '';
my $length = length $temp;
my $count = $length / 60 ;
my $rest = $length % 60;
for($j=0;$j<=$count;$j++)
{
my $line = substr($temp,60*$j,60);
                         if( $line )
                          {
                          $fasta .=  $line."\n";
                          }
}
              return ($fasta);
}

sub anti_reverse{
              my $string=$_[0];
                 $string =~ s/\W//g;
              $string=reverse($string);
              $string=~ tr/ATCGatcg/TAGCtagc/;
              return($string);
}


sub bowtie2_rRNA
{
      my ($data_dir,$file_type,$read_suffix1,$read_suffix2,$reads,$rRNA_index,$read_type)=@_;
      if($read_type eq "P")
      {   
                my ($read1,$read2)=("$reads"."$read_suffix1".".$file_type","$reads"."$read_suffix2".".$file_type");
                unless(-f "$data_dir/$read1" && -f "$data_dir/$read2")
                {
		            $read1.=".gz";
					$read2.=".gz"; 
		          }
									 
                my $output = $reads."_bowtie2_rRNA";
                my $cmd="bowtie2 -t -p 10 --fr -x $rRNA_index -1 $data_dir/$read1 -2 $data_dir/$read2 -S $output.sam 2> $output.log";
                        print $cmd,"\n"; system($cmd), unless(-f "$output.log");
                   $cmd ="rm -f $output.sam";
                        print $cmd,"\n"; system($cmd), if(-f "$output.sam");
		}
		else
		{
			      my $read1="$reads.$file_type";
			      unless(-f "$data_dir/$read1")
                  {
		            $read1.=".gz";
		          }
					
			      
			      my $output = $reads."_bowtie2_rRNA";
                  my $cmd="bowtie2 -t -p 10 --fr -x $rRNA_index -U $data_dir/$read1 -S $output.sam 2> $output.log";
                        print $cmd,"\n"; system($cmd), unless(-f "$output.log");
                     $cmd ="rm -f $output.sam";
                        print $cmd,"\n"; system($cmd), if(-f "$output.sam");
			}
}

sub star_rRNA
{
      my ($data_dir,$file_type,$read_suffix1,$read_suffix2,$reads,$rRNA_index)=@_;
      my ($read1,$read2)=("$reads"."$read_suffix1".".$file_type","$reads"."$read_suffix2".".$file_type");
      unless(-f "$data_dir/$read1" && -f "$data_dir/$read2")
      {
		            $read1.=".gz";
					$read2.=".gz"; 
		}
									 
      my $output = $reads."_bowtie2_rRNA";
      my $cmd="bowtie2 -t -p 10 --fr -x $rRNA_index -1 $data_dir/$read1 -2 $data_dir/$read2 -S $output.sam 2> $output.log";
              print $cmd,"\n"; system($cmd), unless(-f "$output.log");
         $cmd ="rm -f $output.sam";
              print $cmd,"\n"; system($cmd), if(-f "$output.sam");
}

sub get_circRNA_bed12
{
my ($cicr,$poss_inf,$head)=@_;
open (POSS, "$poss_inf.txt") or die "error(input1):$!";
open (CIRC, "$cicr.txt") or die "error(input2):$!";
open(OUTPUT, ">$cicr.bed") or die "error (output1):$!";
print OUTPUT "$head\n";
my $line;
my %acc;
while ( $line= <POSS> )
{        $line=~ s/[\r\n]//g;
        my @terms = split(/\t/, $line);
        my $acc = $terms[0];
        $acc{$acc}=$line;
}

while ( $line= <CIRC> )
{        chomp $line;
	 $line=~ s/[\r\n]//g;
        my @terms = split(/\t/, $line);
        my $circ_acc=$terms[3];
        my $acc = $terms[8];
        my $start= $terms[1];
        my $end= $terms[2];
        if(exists($acc{$acc})  && $terms[11] eq 'exonic' )
        {
             my @term= split(/\t/, $acc{$acc});
                my @tstarts=split(/,/, $term[9]);
                my @sizes=split(/,/, $term[7]);
                my $se; my $ee;
                for(my $i=0;$i<=$#sizes;$i++)
                {
                      if($start >= $tstarts[$i] && $start < ($tstarts[$i]+$sizes[$i]))
                      {
                           $se=$i;
                      }
                      if($end > $tstarts[$i] && $end <= ($tstarts[$i]+$sizes[$i]))
                      {
                            $ee=$i;
                      }
                }
                my $blockcount=$ee - $se + 1;
                my $csizes; my $cstarts; my @cstarts; my @csizes;
                my $j=0;
                     for(my $i=$se;$i<=$ee;$i++)
                     {

                            $cstarts[$j]=$tstarts[$i];
                            $csizes[$j]=$sizes[$i];
                         if($i == $se)
                         {
                           $cstarts[$j]=$start;
                           $csizes[$j]=$tstarts[$i] + $sizes[$i] - $start;
                         }
                         elsif($i == $ee)
                         {
                           $csizes[$j]=$end - $cstarts[$j];
                         }
                         $j++;
                      } #### for
                      $csizes=join(",",@csizes);
                      $csizes.=",";
                      for(my $j=0; $j<$blockcount;$j++)
                      {
                         $cstarts[$j]=$cstarts[$j]-$terms[1];
                      }
                      $cstarts=join(",",@cstarts);
                      $cstarts.=",";
                    $terms[5]='+',  if($terms[5] eq '*');
        print OUTPUT "$terms[0]\t$terms[1]\t$terms[2]\t$circ_acc\t$terms[4]\t$terms[5]\t$terms[2]\t$terms[2]\t255,0,0\t$blockcount\t$csizes\t$cstarts\n";
        }###  exists
        else
        {
         my $blockcount=1; my $size=$terms[2]-$terms[1];
            $terms[5]='+',  if($terms[5] eq '*');
        print OUTPUT "$terms[0]\t$terms[1]\t$terms[2]\t$circ_acc\t$terms[4]\t$terms[5]\t$terms[2]\t$terms[2]\t255,0,0\t$blockcount\t$size,\t0,\n";
        }

}


close POSS;
close CIRC;
close OUTPUT;
}

sub get_circRNA_expression_dcc
{
        my ($projectid)=$_[0];
        my $num = &get_day;
        my %expression;
        my %annotation=();
        my %strand=();
        my %alignment;

        my @files=<*.fq.line_count>;
        chop(@files),foreach(1..14);
        print "@files\n";
        foreach my $file(@files)
        {
                if(-f "$file.fq.line_count")
                {
                  open (INPUT, "$file.fq.line_count") or die "error(can't open $file.count):$!";
                  my $line=<INPUT>;
                  chomp $line;
                   $line=~ s/[\r\n]//g;
                  $line =~ /^(\d+)/;
                  $alignment{$file}=$1;
                  print "$file.fq.line_count\t$alignment{$file}\n";
                  close INPUT;
                }
        }
        my $para_num = $alignment{$files[0]};
        foreach my $file(@files)
        {
            $para_num = $alignment{$file}, if($para_num <= $alignment{$file});
        }
        print "normalization: $para_num\n";

        ###      (CircCoordinates CircRNACount CircSkipJunctions);
       	open (INPUT1, "CircCoordinates") or die "error(can't open CircCoordinates):$!";
        open (INPUT2, "CircRNACount") or die "error(can't open CircRNACount):$!";
        open(OUTPUT, ">$projectid\_CircRNAs_expression.txt") or die "error (can't create CircRNAs_expression.txt):$!";
                my $line;
                # $line=<INPUT1>;
           $line=<INPUT2>;
           chomp $line;
            $line=~ s/[\r\n]//g;
           my @terms=split(/\t/,$line);
           my $sample_num = @terms - 3;
           my @samples = @terms[3..$#terms];
           chop(@samples), foreach(1..21);
           print "$_\n", foreach (@samples);
           $line = join("\t",@samples);
           print OUTPUT "CircRNAID\t$line\t$line\tchrom\tstrand\ttxStart\ttxEnd\n";

                while($line=<INPUT1>)
                {
        	        chomp $line;
        	         $line=~ s/[\r\n]//g;
                        my @terms=split(/\t/,$line);
                        my $circRNA="$terms[0]:$terms[1]-$terms[2]$terms[5]";
                        $terms[1]--;
                        unless(exists($annotation{$circRNA}))
                        {
                           $annotation{$circRNA} = join("\t",@terms[0,1,2,5]);
                           $strand{$circRNA}=$terms[5];
                        }
                        else
                        {
                           print "find a duplicate circRNA:$circRNA\n";
                        }
                        $line=<INPUT2>;
                        chomp $line;
                         $line=~ s/[\r\n]//g;
                     @terms=split(/\t/,$line);
                     my @data=@terms[3..$#terms];
                     my @normalized;
                       for(my $i=0;$i<$sample_num;$i++)
                       {
                         if($data[$i] == 0)
                         {
                               my $normalized = 1/$alignment{$samples[$i]}*$para_num;
                                  $normalized = log($normalized)/log(2);
                                  $normalized[$i]=$normalized;

                         }
                         else
                         {
                               my $normalized = $data[$i]/$alignment{$samples[$i]}*$para_num;
                                  $normalized = log($normalized)/log(2);
                                  $normalized[$i]=$normalized;
                         }
                       }
                       my $data = join("\t",@data);
                       my $normalized=join("\t",@normalized);
                       print OUTPUT "$circRNA\t$data\t$normalized\t$annotation{$circRNA}\n";

                }
        	close INPUT1;
                close INPUT2;
                close OUTPUT;

        open(BED6, ">$projectid\_CircRNAs.bed") or die "error (can't create $projectid\_CircRNAs.bed):$!";
        foreach my $circRNA (keys %annotation)
        {
              my @anno = split(/\t/,$annotation{$circRNA});
              my $line = join("\t",$anno[0],$anno[1],$anno[2],"$circRNA",1000,$anno[3]);
              print BED6 "$line\n";
        }
        close BED6;
           print "\t\tsuccessful get the circRNAs expression!\n";
}

sub hash_md5_perl
{
       my $filename=shift;
        open (INPUT, "$filename") or die "error(can't open $filename):$!";
        binmode(INPUT);
        my $hash_md5= Digest::MD5->new->addfile(*INPUT)->hexdigest;
        close INPUT;
        return($hash_md5);
}

# &delete_column("filename",[added_columns],"output_filename");

sub delete_column
{
         my ($lista,$ref,$output)=@_;
open (LIST, "$lista.txt") or die "error($lista):$!";
open(CONTAIN, ">$output.txt") or die "error (output1):$!";

my %sublist = ();
my $line;
my $column_max=0;
while ( $line= <LIST>)
{     chomp $line;
	 $line=~ s/[\r\n]//g;
      my @name = split(/\t/,$line);
      my $columns =@name;
      $column_max=$columns, if($column_max<$columns);
}
seek(LIST,0,0);
my $add_columns=@{$ref};
print "delete $add_columns columns!\n";
my @array = sort {$a<=>$b} @{$ref};
my $j=0;
for(my $i=0;$i<=$#array;$i++)
{
	$array[$i]=$array[$i]-$i;
}
while ( $line= <LIST>)
{     chomp $line;
	 $line=~ s/[\r\n]//g;
      my @name = split(/\t/,$line);
                  for(my $i=0;$i<$column_max;$i++)
                  {
					  unless(defined($name[$i]))
                       {
                           $name[$i]='';
                       }					  
				  }
				 for(my $i=0;$i<=$#array;$i++)
				 {				  
                    splice(@name,$array[$i],1);
			     }
		$line = join("\t",@name);
		print CONTAIN "$line\n";
}

close LIST;
close CONTAIN;
print "delete columns!\n";
}


sub add_column
{
         my ($lista,$lncfather,$col1,$col2,$ref,$output,$head_tag)=@_;
open (LIST, "$lista.txt") or die "error($lista):$!";
open (TOTAL, "$lncfather.txt") or die "error($lncfather):$!";
open(CONTAIN, ">$output.txt") or die "error (output1):$!";
### if tag >0, the head will be added into the results.
my %sublist = ();
my $line;
if($head_tag)
{
         $line= <LIST>;	
         $line=~ s/[\r\n]//g;
         chomp $line;
      my @name = split(/\t/,$line);
       for(my $i=0;$i<=$#name;$i++)
         {
           unless(defined($name[$i]))
           {
                  $name[$i]='';
           }
         }
        my $name=$name[$col1];
        # print "$name\n";
      if($name)
      {
          if(defined($name))
          {
                  foreach my $key(@{$ref})
                  {
					  unless(defined($name[$key]))
                       {
                           $name[$key]='';
                       }					  
				  }
                  $sublist{$name} = join("\t",@name[@{$ref}]);
                  $sublist{'head'}=$sublist{$name};
          }
      }	
	
	}
while ( $line= <LIST>)
{     chomp $line;
	  $line=~ s/[\r\n]//g;
      my @name = split(/\t/,$line);
       for(my $i=0;$i<=$#name;$i++)
         {
           unless(defined($name[$i]))
           {
                  $name[$i]='';
           }
         }
        my $name=$name[$col1];
        # print "$name\n";
      if($name)
      {
          if(defined($name))
          {
                  foreach my $key(@{$ref})
                  {
					  unless(defined($name[$key]))
                       {
                           $name[$key]='';
                       }					  
				  }
                  $sublist{$name} = join("\t",@name[@{$ref}]);
          }
      }
}
my $count = keys(%sublist);
my %gotlist = ();
my $add_columns=@{$ref};
print "add $add_columns columns!\n";

if($head_tag)
{
         $line= <TOTAL>;
         chomp $line;
         $line=~ s/[\r\n]//g;
        my @terms = split(/\t/, $line);
        my $name = $terms[$col2];	
        print CONTAIN "$line\t";
        print CONTAIN "$sublist{'head'}\n";
	
}
while ( $line= <TOTAL> )
{
  if( $line =~ /^\#/)
   {  print "$line";   }
   else
   {
        chomp $line;
        $line=~ s/[\r\n]//g;
        my $name = "KKKKKKK";
        my @terms = split(/\t/, $line);
        $name = $terms[$col2];
       	if ( exists($sublist{$name}))
        {
           $gotlist{$name} = 1;
           print CONTAIN "$line\t";
           print CONTAIN "$sublist{$name}\n";
           unless($sublist{$name})
           {
             print "$name\n";
           }

        }
        else
        {
          #print CONTAIN "$line";
          print CONTAIN "$line","\t " x $add_columns,"\n";
        }
    }

}

close TOTAL;
close LIST;
close CONTAIN;
print "add columns!\n";
}

sub circRNA_forTargetScan_out
{
              my $j=0;
	      my $temp = $_[0];
              $temp =~ s/\W//g;
              my $fasta = '';
my $length = length $temp;
    my $add='';

    if($length > 120000)
    {
       my $left = substr($temp,0,60000);
       my $right = substr($temp,$length-60000,60000);
          $temp=$left.$right;
          $add= substr($temp,0,20);
    }
    elsif($length > 20 )
    {
       $add= substr($temp,0,20);
       $length+=20;
    }
    else
    {
       $add= $temp;
       $length +=$length;
    }
     $temp=$temp.$add;
     $length = length $temp;
my $count = $length / 60 ;
my $rest = $length % 60;
for($j=0;$j<=$count;$j++)
{
my $line = substr($temp,60*$j,60);
                         if( $line )
                          {
                          $fasta .=  $line."\n";
                          }
}
              return ($fasta);
}

sub get_targetscan_format
{
my ($file,$ref,$taxid)=@_;
open (LIST, "$file.txt") or die "error(input1):$!";
open(TEMP, ">$file\_targetscan.txt") or die "error (output1):$!";
print "$file\_targetscan.txt\n";
open(MISS, ">$file.mis") or die "error (output2):$!";
 print TEMP "RefSeqID\tGeneID\tGeneSymbol\tSpeciesID\tUTR_sequence\n";
my %sublist = ();
my $line;
while ( $line= <LIST>)
{     chomp $line;
	 $line=~ s/[\r\n]//g;
      my @name = split(/\t/,$line);
      my $name = $name[0];
      $sublist{$name} = 1;
}
my $count = keys(%sublist);
             # print "there are $count unique record for mirTarget!\n";

my %gotlist = ();
foreach my $source(@{$ref})
{
open (FASTA, "$source") or die "error(input2):$!";
      print "$source\n";
my $name='';
my $seq;
my $fastaline;
OUTER: while ( $fastaline= <FASTA> )
{
        chomp $fastaline;
         $fastaline=~ s/[\r\n]//g;
	$name="KKKKKKK";
	if($fastaline =~ />/)
	{         $fastaline =~ />([\w\:\|\_\.\-\+\d]+)/;
                  $name = $1;
                  #print "name:$name\n";
                  $seq = '';
                 if ( (exists($sublist{$name}))  and (not exists($gotlist{$name})))
                 {

	            	  while($fastaline= <FASTA>)
	           	    {
                          if(not $fastaline =~ />/)
	               		  {
                                   $seq .= $fastaline;
                          }
	          		     else
                          {
                                    $seq = &fa_out($seq);
                                    print TEMP "$name\t$name\t$name\t$taxid\t$seq\n";
                                    $gotlist{$name} = 1;
                                    $seq = '';
                                    redo OUTER;
                         }
         		    }#while
	         }#if
        }##if
}#while OUT
                          if($name ne "KKKKKKK")
                          {
                            if ( (exists($sublist{$name}))  and (not exists($gotlist{$name})))
                               {
                                  $seq = &fa_out($seq);
                                  print TEMP "$name\t$name\t$name\t$taxid\t$seq\n";
                                  $gotlist{$name} = 1;
                                 $seq = '';
                               }
                           }
close FASTA
}#foreach

$count = keys %gotlist;
    print "\n\nthere are $count circRNAs for mirTarget!\n";
foreach(keys %sublist)
{
     my $tag = $_;
       if(not exists($gotlist{$tag}))
         {
           print MISS "$tag","\n";
         }#if
}#foreach
 close (LIST);
 close (TEMP);
 close (MISS);
}



sub fa_out
{
              my $j=0;
	      my $temp = $_[0];
              $temp =~ s/\W//g;
              return ($temp);
}

sub get_circRNA_sequence_forTargetScan
{
open (LIST, "$_[0].txt") or die "error(input1):$!";
open(TEMP, ">$_[0]_forTargetScan.fa") or die "error (output1):$!";
open(MISS, ">$_[0].mis") or die "error (output2):$!";

my %sublist = ();
my $line;
while ( $line= <LIST>)
{     chomp $line;
	 $line=~ s/[\r\n]//g;
      my @name = split(/\t/,$line);
      my $name = $name[0];
     # print $name,"\n";
      $sublist{$name} = 1;
}
my $count = keys(%sublist);
# print "there are $count unique record in the list file!\n";

my %gotlist = ();
my $name='';
foreach my $source(@{$_[1]})
{
open (FASTA, "$source") or die "error(input2):$!";
my $seq;
OUTER: while ( my $fastaline= <FASTA> )
{
	$name="KKKKKKK";
		if($fastaline =~ />/)
	{         $fastaline =~ />([\w\:\|\_\.\-\+\d]+)/;
                  $name = $1;
                  $seq = '';
                 if ( (exists($sublist{$name}))  and (not exists($gotlist{$name})))
                 {

	            	  while($fastaline= <FASTA>)
	           	    {
                                    if(not $fastaline =~ />/)
	               		   {
                                    $seq .= $fastaline;
                                    }
	          		     else
                                    {
                                     $seq = &circRNA_forTargetScan_out($seq);
                                    print TEMP ">$name\n$seq";
                                    $gotlist{$name} = 1;
                                    $seq = '';
                                    redo OUTER;
                                    }
         		    }#while
	         }#if
        }##if
}#while OUT
                          if($name ne "KKKKKKK")
                          {
                            if ( (exists($sublist{$name}))  and (not exists($gotlist{$name})))
                               {
                                  $seq = &circRNA_forTargetScan_out($seq);
                                  print TEMP ">$name\n$seq";
                                  $gotlist{$name} = 1;
                                 $seq = '';
                               }
                           }
close FASTA
}#foreach

$count = keys %gotlist;
          print "there are $count CircRNA sequences transformed into TargetScan format!\n";
foreach(keys %sublist)
{
     my $tag = $_;
       if(not exists($gotlist{$tag}))
         {
           print MISS "$tag","\n";
         }#if
}#foreach
 close (LIST);
 close (TEMP);
 close (MISS);
}
sub get_sub_fasta
{
open (LIST, "$_[0].txt") or die "error(input1):$!";
open(TEMP, ">$_[0].fa") or die "error (output1):$!";
open(MISS, ">$_[0].mis") or die "error (output2):$!";

my %sublist = ();
my $line;
while ( $line= <LIST>)
{     chomp $line;
	 $line=~ s/[\r\n]//g;
      my @name = split(/\t/,$line);
      my $name = $name[$_[2]];
     # print $name,"\n";
      $sublist{$name} = 1;
}
my $count = keys(%sublist);
print "there are $count unique record in the list file!\n";

my %gotlist = ();
my @input;
if(ref($_[1]))
{
	@input = @{$_[1]};
	}
else
{
	push @input,$_[1];
	}

foreach my $source(@input)
{
open (FASTA, "$source") or die "error(input2):$!";
my $name;
my $seq;
OUTER: while ( my $fastaline= <FASTA> )
{
	$name="KKKKKKK";
		if($fastaline =~ />/)
	{         $fastaline =~ />([\w\:\_\.\-\+\d]+)/;
                  $name = $1;
                  $seq = '';
                 if ( (exists($sublist{$name}))  and (not exists($gotlist{$name})))
                 {

	            	  while($fastaline= <FASTA>)
	           	    {
                                    if(not $fastaline =~ />/)
	               		   {
                                    $seq .= $fastaline;
                                    }
	          		   else
                                    {
                                    $seq = &fasta_out($seq);
                                    print TEMP ">$name\n$seq";
                                    $gotlist{$name} = 1;
                                    $seq = '';
                                    redo OUTER;
                                    }
         		    }#while
	         }#if
        }##if
}#while OUT
                          if($name ne "KKKKKKK")
                          {
                            if ( (exists($sublist{$name}))  and (not exists($gotlist{$name})))
                               {
                                  $seq = &fasta_out($seq);
                                  print TEMP ">$name\n$seq";
                                  $gotlist{$name} = 1;
                                 $seq = '';
                               }
                           }
close FASTA
}#foreach

$count = keys %gotlist;
print "there are $count unique record in the gotlist file!\n";
foreach(keys %sublist)
{
     my $tag = $_;
       if(not exists($gotlist{$tag}))
         {
           print MISS "$tag","\n";
         }#if
}#foreach
 close (LIST);
 close (TEMP);
 close (MISS);
}

sub get_fasta_length
{
print "inference the $_[0].fa sequence length..................!\n";
open (SEQUENCE1, "$_[0].fa") or die "error($_[0].fa):$!";
open(SEQUENCE2, ">temp.fa") or die "error (output):$!";
while(my $seq = <SEQUENCE1>)
{    if( $seq =~ />/)
	{ 		print SEQUENCE2 "\n$seq";			}
	else
	{  chomp($seq);
		 $seq =~ s/[\r\n]//g;
		print SEQUENCE2 "$seq";}
	}
	close(SEQUENCE1);
close(SEQUENCE2);

open (SEQUENCE1, "temp.fa") or die "error(input):$!";
open(SEQUENCE2, ">$_[0]\_length.txt") or die "error (output):$!";
# 打开sequence2.seq文件，可以向文件中写入去回车后的DNA序列。写前会删除文件以前的内容。
print SEQUENCE2 "name\tpredicted_sequence_length\n";
while(my $name = <SEQUENCE1>)
{ if($name =~ />/){
         chomp $name;
          $name=~ s/[\r\n]//g;
         $name =~ s/>//g;
       my $seq = <SEQUENCE1>;
             $seq =~ s/[\r\n]//g;
	my $seqlength = length($seq);
     print SEQUENCE2 "$name\t$seqlength\n";
	}
        }
close (SEQUENCE1);
close (SEQUENCE2);
unlink "temp.fa";
}


sub get_taxid
{
  my $org = shift;
  $org = lc($org);
=pod
human          9606
mouse          10090
rat            10116
zebrafish      7955
wheat      4565
chicken      9031
plasmodium falciparum      36329
schistosoma japonicum      6182
dog      9615
xla_ref_v2
=cut
my %taxid=();
my %build=();
$taxid{'human'}=9606;       $build{'human'}="HG19";
$taxid{'mouse'}=10090;      $build{'mouse'}="MM10";
$taxid{'rat'}=10116;        $build{'rat'}="RN5";
$taxid{'zebrafish'}=7955;   $build{'zebrafish'}="danRer10";
$taxid{'wheat'}=4565;   $build{'wheat'}="wheat_ensembl29";
$taxid{'chicken'}=9031;   $build{'chicken'}="galGal4";
$taxid{'plasmodium falciparum'}=36329;   $build{'plasmodium falciparum'}="pf3d7_ensembl32";
$taxid{'schistosoma japonicum'}=6182;   $build{'schistosoma japonicum'}="Sjp_WBPS7";
$taxid{'dog'}=9615;   $build{'dog'}="canFam3";
$taxid{'pig'}=9823;   $build{'pig'}="SusScr3";
$taxid{'saccharomyces cerevisiae'}=4932;   $build{'saccharomyces cerevisiae'}="sce_ensembl34";
$taxid{'candida albicans wo-1'}=294748;   $build{'candida albicans wo-1'}="calgo1_ensembl34";
$taxid{'vibrio alginolyticus 12g01'}=314288;   $build{'vibrio alginolyticus 12g01'}="Vag12g01_Ensembl34";
$taxid{'xenopus laevis'}=8355;   $build{'xenopus laevis'}="xla_ref_v2";
$taxid{'alcanivorax dieselolei b5'}=930169;   $build{'alcanivorax dieselolei b5'}="AdiB5_Ensembl35";
#$taxid{'epstein-barr virus'}=10377;   $build{'epstein-barr virus'}="EBV_Decoy";
$taxid{'epstein-barr virus'}=10376;   $build{'epstein-barr virus'}="EBV_ViralProj20959";
$taxid{'rice'}=39947;   $build{'rice'}="IRGSP-1.0";
$taxid{'petunia axillaris'}=33119;   $build{'petunia axillaris'}="SGN-v1.6.2";
$taxid{'rabbit'}=9986;   $build{'rabbit'}="Ocu_Ensembl92";
$taxid{'helicoverpa armigera'}=29058;   $build{'helicoverpa armigera'}="Harm1.0";

          if(exists($taxid{$org}))
          {
                 print "\t\t\ttaxid:$taxid{$org}\n";
                 return($taxid{$org},$build{$org});
          }
          else
          {
                 die("unknown species, please check the org $org or add taxid list.");
          }

}


sub get_expression_all_txt
{
   my ($anno,$expression,$sample_count,$sampleid)=@_;
   open (LIST, "$anno.txt") or die "error($anno):$!";
   open (TOTAL, "$expression.txt") or die "error($expression):$!";
   open(CONTAIN, ">all.txt") or die "error (output1):$!";

my %sublist = ();
my $line;
while ( $line= <LIST>)
{     
	  chomp $line;
	  $line=~ s/[\r\n]//g;
      my @name = split(/\t/,$line);
      my $name = $name[3];
         $line=join("\t",@name[0..2,5..$#name]);
      $sublist{$name} = $line;
}
$sublist{'CircRNAID'} = $sublist{'name'};
my %gotlist = ();
$line= <TOTAL>;
chomp $line;
 $line=~ s/[\r\n]//g;
my @terms=split(/\t/, $line);
my $sn;
for(my $i=1;$i<=$#terms;$i++)
{
	if($terms[$i] eq 'chrom')
	{
		$sn=($i-1)/2;
		last;
		}
}
my @index=();
for(my $i=1;$i<=$sn;$i++)
{
   if(exists($sampleid->{$terms[$i]}))
   {
         $terms[$i]='['.$terms[$i].'](raw)';
         push @index,$i;
   }
   else
   {
         print "$terms[$i]\n";
   }
}
for(my $i=$sn+1;$i<=$sn*2;$i++)
{
   if(exists($sampleid->{$terms[$i]}))
   {
         $terms[$i]='['.$terms[$i].'](normalized)';
         push @index,$i;
   }
   else
   {
         print "$terms[$i]\n";
   }
}
$line = join("\t",$terms[0],@terms[@index]);
print CONTAIN "$line\t$sublist{'CircRNAID'}\n";


while ( $line= <TOTAL> )
{
  if( $line =~ /^\#/)
   {  print "$line";   }
   else
   {
        my $name = "KKKKKKK";
        chomp $name;
         $line=~ s/[\r\n]//g;
        my @terms = split(/\t/, $line);
           $name = $terms[0];
       	if ( exists($sublist{$name}))
        {
           $gotlist{$name} = 1;
           $line=join("\t",$terms[0],@terms[@index]);
           print CONTAIN "$line\t$sublist{$name}\n";
        }
         else
         {
              return("\n\n\nFind an un-annotated circRNA $terms[0]\n");
         }
    }

}
close TOTAL;
close LIST;
close CONTAIN;
# print "successful get the sublist!\n";
}


sub get_junction_reads_from_expression
{
   my ($expression,$sample_count,$sampleindex)=@_;
   open (TOTAL, "$expression.txt") or die "error($expression):$!";
   open(CONTAIN, ">junction_reads.txt") or die "error (output1):$!";
my $line;
my %gotlist = ();
$line= <TOTAL>;
chomp $line;
 $line=~ s/[\r\n]//g;
my @terms=split(/\t/, $line);
my $sn;
for(my $i=1;$i<=$#terms;$i++)
{
	if($terms[$i] eq 'chrom')
	{
		$sn=($i-1)/2;
		last;
		}
}
my @index=();

for(my $i=1;$i<=$sn;$i++)
{
   if(exists($sampleindex->{$terms[$i]}))
   {
         push @index,$i;
   }
   else
   {
         print "$terms[$i]\n";
   }
}

$line = join("\t",$terms[0],@terms[@index]);
print CONTAIN "$line\n";
while ( $line= <TOTAL> )
{
  if( $line =~ /^\#/)
   {  print "$line";   }
   else
   {
        my $name = "KKKKKKK";
        chomp $name;
         $name=~ s/[\r\n]//g;
        my @terms = split(/\t/, $line);
           $name = $terms[0];
           $gotlist{$name} = 1;
           if(sum(@terms[@index])>0)
           {
             $line=join("\t",$terms[0],@terms[@index]);
             print CONTAIN "$line\n";
	       }
    }

}
close TOTAL;
close CONTAIN;
# print "successful get the sublist!\n";
}





sub check_config_linux_utf8
{
	my $file = shift;
	open(INPUT, "$file") or die "error (can't open $file):$!";
	open(OUTPUT, ">$file\_temp") or die "error (can't open $file\_temp):$!";
	<INPUT>;
	s/^\\ufeff//;
	while(<INPUT>)
	{
		s/[\r\n]//g;
		print OUTPUT "$_\n";
	}
	close INPUT;
	close OUTPUT;
	rename("$file\_temp","$file");	
}

=pod
sub read_config
{

print "Reading the config file....................................................\n";
  my %usr;
  my %samples;
  my %sampleid;
  my %sample_group;
  my $file;
  if($_[0])
  {
	  $file=$_[0];
	  }
  else
  {
       my @file=<*config.txt>;
       $file = $file[0];
   }
    #&check_config_linux_utf8($file);
   open(INPUT, "$file") or die "error (can't open $file):$!";
   my $line;
   my $off_on;
   while (<INPUT>) {
        if (!/^#/) {
            if (/^name\s+=\s+(.*?)$/){
                my $name=$1;
                $usr{'name'}=$name;
                $name=~s/\(.*?\)//g;
            }

            $usr{'prj'}=$1 if (/^projcet_number\s+=\s+(.*?)$/);
            $usr{'dept'}=$1 if (/^department\s+=\s+(.*?)$/);
            $usr{'spe'}=$1 if (/^species\s+=\s+(.*?)$/);
            $usr{'type'}=$1 if (/^sample_type\s+=\s+(.*?)$/);
            $usr{'spn'}=$1 if (/^sample_number\s+=\s+(.*?)$/);
            $usr{'flag'}=$1 if (/^XoutY_X\s+=\s+(.*?)$/);


            if(/\[sample_name\]/)
            {
               my $id=1;
                 while(<INPUT>)
                 {
                      if (/=/){
                             chomp;
                             s/[\r\n]//g;
                             my @tem=split/\t/,$_;
                             if($tem[0])
                             {
                               $samples{$tem[0]}=$tem[2];
                               $sampleid{$tem[0]}=$id;
                               $id++;
                             }
                      }
                      else
                      {
                          last;
                      }
                 }
            }
            if(/\[sample_group\]/)
            {
                 while(<INPUT>)
                 {
                      if (/=/){
                             chomp;
                             s/[\r\n]//g;
                             my @tem=split/\t/,$_;
                             $sample_group{$tem[2]}=$tem[3],if($tem[0]);
                      }
                      else
                      {
                          last;
                      }
                 }
            }
        }  ### if ! #
    } ### while
   close INPUT;
            # print "\t\t\tprojectID:$usr{'prj'}\n";
            #  print "\t\t\tCustomer:$usr{'name'}\n";
            # print "\t\t\tdepartment:$usr{'dept'}\n";
            # print "\t\t\torganism:$usr{'spe'}\n";
            # print "\t\t\tSample count:$usr{'spn'}\n";
            # print "\t\t\tXoutY_X:$usr{'flag'}\n";
            return(\%usr,\%samples,\%sampleid,\%sample_group);
}
=cut

sub read_config
{
	my $config_txt=shift;
print "Reading the config file....................................................\n";
unless($config_txt)
{
my @config=<*config.txt>;
   $config_txt = $config[0];
}
unless(-f $config_txt)
{
   die("can't find config_txt file!\n");	
}
my $cfg = Config::Tiny->new;
$cfg = Config::Tiny->read($config_txt);

my($usr,$samples,$sampleid,$sample_group);

            $usr->{'name'}=$cfg->{'user_infomation'}->{'name'};
            $usr->{'prj'}=$cfg->{'user_infomation'}->{'projcet_number'};
            $usr->{'dept'}=$cfg->{'user_infomation'}->{'department'};
            $usr->{'spe'}=$cfg->{'user_infomation'}->{'species'};
            $usr->{'type'}=$cfg->{'user_infomation'}->{'sample_type'};
            $usr->{'spn'}=$cfg->{'user_infomation'}->{'sample_number'};
            # $usr{'flag'}=$cfg->{'user_infomation'}->{'XoutY_X'};
            foreach my $fq ( sort keys %{$cfg->{'sample_name'}})
            {
			    $samples->{$fq}=$cfg->{'sample_name'}->{$fq};
			}
			foreach my $id ( sort {$a <=> $b} keys %{$cfg->{'sample_group'}})
            {
			    my @terms =split("\t",$cfg->{'sample_group'}->{$id});
			    $sample_group->{$terms[0]}=$terms[1];
			    $sampleid->{$terms[0]}=$id;
			} 
            return($usr,$samples,$sampleid,$sample_group);
}

sub two_excel_writer
{
	print "\t\t\t\t\t\t\ttwo_excel_writer\n";
	my ($sampleid,$samples,$sample_group,$raw_reads,$q30,$clean_reads,$mapped,$circ_count,$usr,$build)=@_;
	print "$usr\t$usr->{'spn'}\n";	
	
   my $workbook = Excel::Writer::XLSX->new('read_statistics.xlsx');
   my $worksheet = $workbook->add_worksheet();
   my $default=$workbook->add_format();
      $default->set_font('Times New Roman');
      $default->set_size(11);
      $default->set_border(1);
      $default->set_align('center');
      
   my $title0=$workbook->add_format();
      $title0->set_font('Times New Roman');
      $title0->set_bold();
      $title0->set_size(16);
      
   my $title1=$workbook->add_format();
      $title1->set_font('Times New Roman');
      $title1->set_bold();
      $title1->set_size(11);
      $title1->set_bg_color( '#00b0f0' );
      $title1->set_border(1);
      $title1->set_align('center');
      
   my $format_ratio=$workbook->add_format();
      $format_ratio->set_font('Times New Roman');
      $format_ratio->set_size(11);
      $format_ratio->set_num_format(10); 
      $format_ratio->set_border(1); 
      $format_ratio->set_align('center');
      
   my $format_number=$workbook->add_format();
      $format_number->set_font('Times New Roman');
      $format_number->set_size(11);
      $format_number->set_num_format(3); 
      $format_number->set_border(1);    
      $format_number->set_align('center');
     
   
   $worksheet->set_column( 0, 7, 18 );  
   $worksheet->write(0,0,"Table 2. Reads statistics",$title0);
   $worksheet->write(1,0,"Sample",$title1);
   $worksheet->write(1,1,"Raw Reads",$title1);
   $worksheet->write(1,2,"Q30",$title1);
   $worksheet->write(1,3,"Clean Reads",$title1);
   $worksheet->write(1,4,"Clean Ratio",$title1);
   $worksheet->write(1,5,"Mapped Reads",$title1);
   $worksheet->write(1,6,"Mapped Ratio",$title1);
   $worksheet->write(1,7,"CircRNA Number",$title1);

   my $row=3;
   foreach my $sample (sort { $sampleid->{$a} <=> $sampleid->{$b} } keys %{$sampleid})
   {
	   unless(exists($q30->{$sample}))
	   {
		   $q30->{$sample}=$clean_reads->{$sample};
		   }
	   unless(exists($raw_reads->{$sample}))
	   {
		   $raw_reads->{$sample}=0;
		}
	   
      $worksheet->write($row-1,0,$sample,$default);
      $worksheet->write($row-1,1,$raw_reads->{$sample},$format_number);
      $worksheet->write($row-1,2,$q30->{$sample}/100,$format_ratio);
      $worksheet->write($row-1,3,$clean_reads->{$sample},$format_number);
      my $clean_ratio=0;
      if($raw_reads->{$sample})
      {
         $clean_ratio = $clean_reads->{$sample}/$raw_reads->{$sample};
       }
      $worksheet->write($row-1,4,$clean_ratio,$format_ratio);
      $worksheet->write($row-1,5,$mapped->{$sample},$format_number);
      my $mapped_ratio=0;
      if(exists($clean_reads->{$sample}) && $clean_reads->{$sample}>0)
      {
           $mapped_ratio = $mapped->{$sample}/$clean_reads->{$sample};
       }
      $worksheet->write($row-1,6,$mapped_ratio,$format_ratio);
      $worksheet->write($row-1,7,$circ_count->{$sample},$format_number);
      $row++;
   }
   $workbook->close();
   ########################################################################################
    $workbook = Excel::Writer::XLSX->new('sample & groups.xlsx');
    $worksheet = $workbook->add_worksheet();
    
      $default=$workbook->add_format();
      $default->set_font('Times New Roman');
      $default->set_size(11);
      $default->set_border(1);
      
      $title0=$workbook->add_format();
      $title0->set_font('Times New Roman');
      $title0->set_bold();
      $title0->set_size(16);
      
      $title1=$workbook->add_format();
      $title1->set_font('Times New Roman');
      $title1->set_bold();
      $title1->set_size(11);
      $title1->set_bg_color( '#00b0f0' );
      $title1->set_border(1);
      $title1->set_align('center');
      
      my $title1_left=$workbook->add_format();
      $title1_left->set_font('Times New Roman');
      $title1_left->set_bold();
      $title1_left->set_size(11);
      $title1_left->set_bg_color( '#00b0f0' );
      $title1_left->set_border(1);
      $title1_left->set_align('left');
      
      my $format_left=$workbook->add_format();
      $format_left->set_font('Times New Roman');
      $format_left->set_size(11);
      $format_left->set_border(1);
      $format_left->set_align('left');
      
      my $format_center=$workbook->add_format();
      $format_center->set_font('Times New Roman');
      $format_center->set_size(11);
      $format_center->set_border(1);
      $format_center->set_align('center');

   $worksheet->set_column( 0, 3, 18 );
   $worksheet->write(0,0,"Table 1. Sample Information",$title0);
   $worksheet->write(1,0,"Species",$title1_left);
   $worksheet->write(1,1,$usr->{'spe'},$format_left);
   $worksheet->write(2,0,"Sample type",$title1_left);
   $worksheet->write(2,1,$usr->{'type'},$format_left);
   $worksheet->write(3,0,"Sample number",$title1_left);
   $worksheet->write(3,1,$usr->{'spn'},$format_left);
   $worksheet->write(4,0,"Sequencing mode",$title1_left);
   $worksheet->write(4,1,"Paired-end",$format_left);
   $worksheet->write(5,0,"Genome build",$title1_left);
   $worksheet->write(5,1,$build,$format_left);
   $worksheet->write(6,0,"Sample ID",$title1);
   $worksheet->write(6,1,"Sample Name",$title1);
   $worksheet->write(6,2,"Group Name",$title1);
   $worksheet->write(6,3,"Quality Status",$title1);

   $row=1;
   foreach my $sample (sort { $sampleid->{$a} <=> $sampleid->{$b} } keys %{$sampleid})
   {
      $worksheet->write($row+6,0,$row,$format_center);
      $worksheet->write($row+6,1,$sample,$format_center);
      $worksheet->write($row+6,2,$sample_group->{$sample},$format_center);
      $worksheet->write($row+6,3,"OK",$format_center);
      $row++;
   }
   $workbook->close();
}

sub get_differentially_expressed_circRNA_list
{
&gettime;
print "get differentially expressed circRNA sequences...........................................\n";
my $file4 = shift;
print $file4,"\n";
        unless(-f "$file4")
        {
               die("Can't find file $file4!\n");
        }
my %sublist = ();
        my $parser   = Spreadsheet::ParseXLSX->new;
        my $excel = $parser->parse($file4);
        for my $worksheet ( $excel->worksheets() ) {
                  my $sheetname =$worksheet->get_name();
                  print "$sheetname\n";
                  &gettime;
                  if($sheetname =~ /vs/)
                  {
                       my ( $row_min, $row_max ) = $worksheet->row_range();
                       my ( $col_min, $col_max ) = $worksheet->col_range();
                      my $rowtag;
                      my $coltag;
                      my $found=0;
                      print "excel range: $row_min\t$row_max\t$col_min\t$col_max\n";
                       for(my $i=$row_min;$i<=$row_max;$i++)
                       {
                            for(my $j=$col_min;$j<=$col_max;$j++)
                             {
                                my $cell = $worksheet->get_cell( $i, $j );
                                   next unless $cell;
                                my $value = $cell->value();
                                # print "$value\n", if($j <1);
                                if($value && $value eq 'CircRNAID')
                                {
                                   $rowtag=$i;
                                   $coltag=$j;
                                   $found++;
                                   print "CircRNAID\n";
                                   last;
                                }
                             }
                             last,if($found);
                       }
                       print "circRNAID coordinate: $rowtag\t$coltag\n";

                       for(my $i=$rowtag+1;$i<=$row_max;$i++)
                       {
                            my $cell = $worksheet->get_cell( $i, $coltag );
                                   next unless $cell;
                            my $value = $cell->value();
                               if($value)
                               {
                                       $sublist{$value}=1;
                               }
                       }
                  }## sheetname vs
              } ### sheet

my $count = keys(%sublist);
print "there are $count Differentially expressed circRNAs!\n";
my $output="Differentially expressed circRNA sequences";
open(TEMP, ">$output.txt") or die "error (output1):$!";

foreach(keys %sublist)
{
           print TEMP "$_\n";
}#foreach
close TEMP;
}



sub txt2xlsx
{
            my $txt = shift;
            my $excel_new = Excel::Writer::XLSX->new("$txt.xlsx");
            my $worksheet = $excel_new->add_worksheet();
            open (INPUT, "$txt.txt") or die "error(input2):$!";
            my $line;
            my $columns=0;
            while ( $line= <INPUT>)
            {     chomp $line;
				 $line=~ s/[\r\n]//g;
                  my @name = split(/\t/,$line);
                  my $column = @name;
                  $columns=$column,if($columns<$column);
            }
            seek(INPUT,0,0);
            my $row=0;
            while ( $line= <INPUT>)
            {     chomp $line;
				 $line=~ s/[\r\n]//g;
                  my @name = split(/\t/,$line);
                  for(my $i=0;$i<=$columns;$i++)
                     {
                       unless(defined($name[$i]))
                       {
                              $name[$i]='';
                       }
                     }
                  for(my $i=0;$i<=$columns;$i++)
                  {
                     $worksheet->write($row,$i,$name[$i]);
                  }
                  $row++;
            }
            close INPUT;
            $excel_new->close();
                 #       print "The table are added into excels!\n";
}

sub read_file_type
{
        my $data_dir = shift;
        my $file_type_ref;
        my ($file_type,$read_type,$p1,$p2);
        my @files=<$data_dir/*>; 
        @files=map{$_=basename($_)} @files;      
 
        foreach my $file(@files)
        {
		      print "raw data file: $file\n";
		      if($file =~ /\.fastq(\.gz){0,1}$/)
		      {
				  $file_type = 'fastq';
				  last;
			  }
		}
		unless($file_type)
		{
			foreach my $file(@files)
      	  {	
			  if($file =~ /\.fq(\.gz){0,1}$/)
		      {
				  $file_type = 'fq';
				  last;
			  }
			}
		}
		unless($file_type)
		{
			foreach my $file(@files)
        	{
			  
			  if($file =~ /\.txt(\.gz){0,1}$/)
		      {
				  $file_type = 'txt';
				  last;
			  }		
			}
		}
		print "file_type: $file_type\n", if($file_type);
		
		if($file_type)
		{
			$file_type_ref->{'file_type'}=$file_type;
			 foreach my $file(@files)
             {
		      	if($file =~ /_R1\.$file_type/)
		      	{
					  $p1="_R1"
				  	}
			  	if($file =~ /_R2\.$file_type/)
		      	{
					  $p2="_R2"
			  	}
			 }
			 
			 unless($p1 && $p2)
			 {
				 foreach my $file(@files)
             	 {
		     	  	if($file =~ /_1\.$file_type/)
		      		 {
					  	 $p1="_1"
				  		 }
			  		 if($file =~ /_2\.$file_type/)
		      		 {
					  	 $p2="_2"
			  		 }
			 	 }
			  }
			 
			 if($p1)
			 {
				 $file_type_ref->{'read_suffix1'}=$p1;
			 }
			 if($p2)
			 {
				 $file_type_ref->{'read_suffix2'}=$p2;
			 }
			 			 
			 if($p1 && $p2)
			 {
				 $read_type='P';
				 $file_type_ref->{'library_type'}=$read_type;
			  }
			  else
			  {
				  $read_type='S';
				  $file_type_ref->{'library_type'}=$read_type;
			  }			 
		}
		else
		{
			print ("can't recagnize raw sequence file type!\n");				
		}
		
		if($read_type eq 'P')
		{
			print "---------------------warning: PPPPPPPPPPPPPPaired-End read----------------------\n";		
		}
		else
		{
			print "---------------------warning: SSSSSSSSSSSSSSingle-End read----------------------\n";
		}	
		return($file_type_ref);	
}

sub collect_md5
{
      my $dir= shift;
      open (OUTPUT, ">md5.fastq.txt") or die "error(can't create md5.fastq.txt):$!";
      my @files=<$dir/*.md5>;
      foreach my $file(sort @files)
      {
		 if(-f $file)
		 {
		  open (INPUT, "$file") or die "error(can't open $file):$!";
		  my $line =<INPUT>;
		  print OUTPUT $line;
		  close INPUT;
	    }
	  }	
	  close OUTPUT;
}

sub get_md5_files
{
       my ($projectid,$sampleid) =@_;
       print "\t\t\tget_md5_files\n";
     open (LIST, "md5.fastq.txt") or die "error(md5.fastq):$!";
     my %md5_hash=();
     my $line;
     while($line =<LIST>)
     {
              chomp $line;
               $line=~ s/[\r\n]//g;
           my ( $file,$hash)=split(/\t/,$line);
                $md5_hash{$file}=$hash;
     }
     close LIST;
             open (OUTPUT, ">$projectid.md5") or die "error($projectid.md5):$!";
     foreach my $sample(sort keys %{$sampleid})
     {
           if(exists($md5_hash{$sample."_R1.fastq.gz"}))
           {

                          print OUTPUT "$sample\_R1.fastq.gz\t",$md5_hash{"$sample\_R1.fastq.gz"},"\n";

           }
           else
           {
                          print("no md5 value for $sample\_R1.fastq.gz\n");
            }
           if(exists($md5_hash{$sample."_R2.fastq.gz"}))
           {
                         print OUTPUT "$sample\_R2.fastq.gz\t",$md5_hash{"$sample\_R2.fastq.gz"},"\n";
           }
           else
           {
                          print("no md5 value for $sample\_R2.fastq.gz\n");
            }

     }
     close OUTPUT;
}


sub inference_cutadapt
{
     my ($data_dir,$file_type,$threshold)=@_;
     my @files=<$data_dir/*.$file_type.length>;
     my %short=();
     my %long=();
     open (OUTPUT, ">cutadapt_summary.txt") or die "error(can't open summary.txt):$!";
     print OUTPUT "file\ttotal\tread number <=$threshold\tread number >$threshold\t<=$threshold ratio\n";
     foreach my $file(sort @files)
     {           
     open (INPUT, "$file") or die "error(can't open $file):$!";
              $short{$file}=0;
              $long{$file}=0;
         while(<INPUT>)
         {
             chomp;
             s/[\r\n]//g;
             my ($length,$count) = split(/\t/,$_,2);
             if($length <= $threshold)
             {
               $short{$file}+= $count;
             }
             else
             {
               $long{$file}+= $count;
             }
         }     
     close INPUT;
                              my $total = $short{$file}+$long{$file};
                              my $ratio = $short{$file}/($short{$file} + $long{$file});
                print OUTPUT "$file\t$total\t$short{$file}\t$long{$file}\t$ratio\n";
     }
     close OUTPUT;
     print "cutadapt information is collected!\n";
     rename("$data_dir/cutadapt_summary.txt","cutadapt_summary.txt");
     &txt2xlsx("cutadapt_summary");
}





sub gzip_fq_files_multiplex_cpu
{
      my ($data_dir,$file_type,$max_threads,$cal_md5) = @_;
      print "gzip_fq_files_multiplex_cpu start: ", &gettime();
      my $semaphore=new Thread::Semaphore($max_threads);
              my @files1=<$data_dir/*.$file_type.gz>; 
	          my @files2=<$data_dir/*.$file_type>; 
              @files1=map{$_=basename($_)} @files1;
              @files2=map{$_=basename($_)} @files2;
          
               chop @files1, foreach(1..3);
               my @files =(@files2,@files1);
      ########  multiplex cpu to calculate circRNA
               foreach my $reads(sort @files)
               {
                 $semaphore->down();
	             my $thread=threads->new(\&gzip_fq_files,$data_dir,$reads,$cal_md5,$semaphore);
	             $thread->detach();
                }
         &waitquit($max_threads,$semaphore);   ############ must
         print "gzip_fq_files_multiplex_cpu complete: ", &gettime;
}
sub gzip_fq_files
{
	my ($data_dir,$file,$hash_cal,$semaphore)=@_;
	print "gzip $data_dir/$file\n";
	if(-f "$data_dir/$file")
	{
	      if(-f "$data_dir/$file.gz")
	      {
			  unlink("$data_dir/$file");
		  }	
		  elsif(-l "$data_dir/$file")
		  {
			 my $cmd="gzip -c $data_dir/$file>$data_dir/$file.gz";
			  print "$cmd\n"; system($cmd);
			  # unlink "$data_dir/$file",if(-f "$data_dir/$file.gz");			  
			  }
		  else		  
		  {
			  my $cmd="gzip $data_dir/$file";
			  print "$cmd\n"; system($cmd);
		  }
	}
	my $hash_tag=0;
	if(defined $hash_cal)
	{
		$hash_tag =$hash_cal; 
		}
	if($hash_tag)
	{
	     unless(-f "$file.gz.md5")
	     {
	     my $hash = &hash_md5_perl("$data_dir/$file.gz");	
	     open (OUTPUT, ">$file.gz.md5") or die "error(can't create $file.gz.md5):$!";	
	     print OUTPUT "$file.gz\t$hash\n";
	     close OUTPUT;
	    }
     }
	$semaphore->up(); ##release signal	
}

sub rm_fq_files
{
	my ($data_dir,$file_type)=@_;
	my @files=<$data_dir/*.$file_type>;
	foreach my $file (@files)
	{
		unlink($file);
	}		
}




sub q30_multiplex_cpu
{
      my ($data_dir,$file_type,$phred,$max_threads) = @_;
      print "q30_multiplex_cpu start: ", &gettime();
      my $semaphore=new Thread::Semaphore($max_threads);
                              my @q30files=<*.q30>;
                               foreach my $file(@q30files)
                               {
                                  my @array=stat("$file");
                                  my $size = $array[7];
                                   unless($size)
                                   {
							       	unlink("$file");
							       }
						        } 
	  my @files1=<$data_dir/*.$file_type.gz>; 
	  my @files2=<$data_dir/*.$file_type>; 
         @files1=map{$_=basename($_)} @files1;
         @files2=map{$_=basename($_)} @files2;
               chop @files1, foreach(1..3);
               my @files =(@files2,@files1);
               my %reads=();
               foreach my $reads(sort @files)
               {
      	             $reads{$reads}=1;
      	             print "$reads\n";
               }
      ########  multiplex cpu to calculate circRNA
               foreach my $reads(sort keys %reads)
               {
                 $semaphore->down();
	             my $thread=threads->new(\&q30_perl,$data_dir,$reads,$phred,$semaphore);
	             $thread->detach();
                }
        &waitquit($max_threads,$semaphore);   ############ must
                               @q30files=();
                               @q30files=<*.q30>;
                               open(OUTPUT, ">q30.txt") or die "error (can't create q30.txt):$!";
                               foreach my $file(@q30files)
                               {
                                  open(INPUT, "$file") or die "error (can't read $file):$!";
                                  my $line=<INPUT>;
                                  print OUTPUT "$line";
                                  close INPUT;
						       }
						       close OUTPUT;
         print "f30_multiplex_cpu complete: ", &gettime;
}
sub  q30_perl
{
                    my ($data_dir,$file,$phred,$semaphore) = @_;
                    if(-f "$data_dir/$file")
                    {
	                        print "$file start: ", &gettime;
	                        &calculate_q30($data_dir,$file,$phred),unless(-f "$file.q30");
				     }
				    elsif(-f "$data_dir/$file.gz")
                    {
						   my $cmd="gzip -dc $data_dir/$file.gz>$data_dir/$file";
                           print "$cmd\n"; system($cmd),unless(-f "$file.q30");
                           print "$file start: ", &gettime;                           
						   &calculate_q30($data_dir,$file,$phred),unless(-f "$file.q30");                           
					}
					       my @array=stat("$file.q30");
                              my $size = $array[7];
                            unless($size)
                            {
								unlink("$file.q30");
								&q30_perl($data_dir,$file,$phred,$semaphore);
							}
                    $semaphore->up(); ##release signal
}

sub calculate_q30
{
	my ($data_dir,$file,$phred) = @_;
	print "calculating q30 for $data_dir/$file..........................\n";
	open(INPUT, "$data_dir/$file") or die "error (can't read $data_dir/$file):$!";
	my $line;
	my $q =0;
	my $q30=0;
	my $number=0;
	while($line=<INPUT>)
	{
		if($line =~ /^\@/)
		{
		  $number++;
		  $line=<INPUT>;
		  $line=<INPUT>;
		  $line=<INPUT>;
		  chomp $line;
		   $line=~ s/[\r\n]//g;
		  my $length = length($line);
		  $q += $length;
		  for(my $i = 0; $i < $length; $i++)
		  {
              my $char = substr($line,$i,1);
              $q30++, if((ord($char) - $phred) >= 30);
          }
		}
	}
	close INPUT;
	open(OUTPUT, ">$file.q30") or die "error (can't create $file.q30):$!";
	my $percentage=0;
	$percentage = sprintf("%.3f",$q30/$q*100), if($q>0);
	print OUTPUT "$file\t$percentage\t$q30\t$q\t$number\n";
	print "$file\t$percentage\n";
	close OUTPUT;
}



sub fq_title_replace_multiplex_cpu
{
      my ($data_dir,$file_type,$read_type,$read_suffix1,$read_suffix2,$machine_flowcell,$max_threads,$th_dir) = @_;
      print "fq_title_modify_multiplex_cpu start: $max_threads cpu", &gettime();
      my $semaphore=new Thread::Semaphore($max_threads);
      my @files=<$data_dir/*.$file_type>; 
         @files=map{$_=basename($_)} @files;
      ########  multiplex cpu to calculate circRNA
=pod
         my %fq=();
         foreach my $file(@files)
         {
			 if($file =~ /(.*)$read_suffix1\.$file_type/)
			 {
				 $file=~ s/$read_suffix1\.$file_type//;
				 $fq{$file}=1;
			 }
			 
			}
=cut			
         foreach my $reads(sort @files)
         {
			 print "ready  $reads\n";
			 my $machine_flowcell_value='';                 
                 if(ref($machine_flowcell) eq 'HASH')
 	                {
						if(exists($machine_flowcell->{$reads}))
						{
						   $machine_flowcell_value=$machine_flowcell->{$reads};
						   print "$reads\t$machine_flowcell_value\n";
					    }
					    else
					    {
							die("can't find the flowcell for $reads!\n");
							}
					}
				 else
				    {
					    $machine_flowcell_value=$machine_flowcell;
					    print "$reads\t$machine_flowcell_value\n";
					 }
				 next,unless($machine_flowcell_value);
                 $semaphore->down();                 
	             my $thread=threads->new(\&fq_title_replace_perl,$data_dir,$reads,$machine_flowcell_value,$th_dir,$semaphore);
	             $thread->detach();
         }
        &waitquit($max_threads,$semaphore);   ############ must
         print "fq_title_modify_multiplex_cpu complete: ", &gettime;
}

sub  fq_title_replace_perl
{
                    my ($data_dir,$file,$machine_flowcell_value,$th_dir,$semaphore) = @_;
                    unless(-f "$th_dir/$file.th.log")
                    {
                            if(-f "$data_dir/$file")
                            {
	                                print "$file start: ", &gettime;
	                                &run_fq_title_replace_perl($data_dir,$th_dir,$file,$machine_flowcell_value);
				             }
				            elsif(-f "$data_dir/$file.gz")
                            {
						           my $cmd="gzip -dc $data_dir/$file.gz>$data_dir/$file";
                                   print "$cmd\n"; system($cmd);
                                   print "$file start: ", &gettime;                           
						           &run_fq_title_replace_perl($data_dir,$th_dir,$file,$machine_flowcell_value);
					        }
					}
					else
					{
						print "$th_dir/$file.th.log exists!\n";
						}		
                    $semaphore->up(); ##release signal
}

sub run_fq_title_replace_perl
{
	my ($data_dir,$th_dir,$file,$machine_flowcell_value) = @_;
	open(INPUT, "$data_dir/$file") or die "error (can't read $file):$!";
	open(OUTPUT, ">$th_dir/$file") or die "error (can't create $file):$!";
	my $line;
	my $q =0;
	my $q30=0;
	while($line=<INPUT>)
	{
		if($line =~ /^\@/)
		{
			my @line = split(/:/,$line);
			   @line[0..2]=split(/:/,$machine_flowcell_value);
			   $line = join(":",@line);
			   print OUTPUT "$line";
			########################
		    $line=<INPUT>;
		    print OUTPUT "$line";
		    $line=<INPUT>;
		    print OUTPUT "$line";
		    $line=<INPUT>;
		    print OUTPUT "$line";
	     } 
	}
	close INPUT;
	close OUTPUT;
	sleep(10);
	my $count=0;
	my $count_new=0;
	$count = &get_line_count("$data_dir/$file");
	$count_new = &get_line_count("$th_dir/$file");	
	unless($count == $count_new)
	{
		&run_fq_title_replace_perl($data_dir,$th_dir,$file,$machine_flowcell_value);
		}		
	else
	{
	    open(OUTPUT, ">$th_dir/$file.th.log") or die "error (can't create $file.th.log):$!";
	    print OUTPUT "$count\t$count_new\n";
	    close OUTPUT;
	    unlink("$data_dir/$file");
	}	          
}



sub uncompress_multiplex_cpu
{
      my ($data_dir,$file_type,$max_threads,$uncompress_dir) = @_;
      print "uncompress_multiplex_cpu start: $data_dir,$file_type,$max_threads,$uncompress_dir,", &gettime();
      my $semaphore=new Thread::Semaphore($max_threads);
      my @files=<$data_dir/*.$file_type.gz>;
        @files=map{$_=basename($_)} @files;        
        foreach my $file(@files)
        {
			print "$file\n";
			}

      ########  multiplex cpu to calculate circRNA
         foreach my $reads(sort @files)
         {
                     print "$reads\n";
                     $semaphore->down();
	             my $thread=threads->new(\&uncompress,$data_dir,$reads,$uncompress_dir,$semaphore);
	                 $thread->detach();
         }
                    &waitquit($max_threads,$semaphore);   ############ must
         print "uncompress_multiplex_cpu complete: ", &gettime;
}

sub  uncompress
{
                    my ($data_dir,$file,$uncompress_dir,$semaphore) = @_;
                    chop $file;  chop $file; chop $file;
                    print "$file\n";
                    my $cmd="gzip -dc $data_dir/$file.gz>$uncompress_dir/$file";
                    if(-f "$data_dir/$file.gz")
                    {
                        if( (not -f "$uncompress_dir/$file") && (not -f "$uncompress_dir/$file.line_count"))
                        {
                         print "$cmd\n"; system($cmd)
				        }
					}
                    $semaphore->up(); ##release signal
}

sub cutadaptor_multiplex_cpu
{
      my ($data_dir,$file_type,$read_suffix1,$read_suffix2,$read_type,$max_threads,$cut_dir,$adaptor1,$adaptor2,$phred,$cutadapt_mirna)=@_;      
      $cutadapt_mirna={},unless(defined($cutadapt_mirna)); 
      print "run_cutadapt start: $file_type\t$read_type ", &gettime();
      my $semaphore=new Thread::Semaphore($max_threads);
      my @files1=<$data_dir/*.$file_type.gz>;
      my @files2=<$data_dir/*.$file_type>;
        @files1=map{$_=basename($_)} @files1;
        @files2=map{$_=basename($_)} @files2;
      
      my $suffix_length  = length($read_suffix1);
      my $filetyp_length = length($file_type);      
      if($read_type eq 'S')
      {
           chop @files1, foreach(1..$filetyp_length+4);
           chop @files2, foreach(1..$filetyp_length+1);
      }
      elsif($read_type eq 'P')
      {
      	   chop @files1, foreach(1..$suffix_length+$filetyp_length+4);
           chop @files2, foreach(1..$suffix_length+$filetyp_length+1);

      	}
      else
      {
      	   die("read_type error!");
      	}
      my @files =(@files2,@files1);
      my %reads=();
      foreach my $reads(@files)
      {
      	    $reads{$reads}=1;
            print "$reads\n";
      }
      ########  multiplex cpu to calculate circRNA
         foreach my $reads(sort keys %reads)
         {
                 my $adaptor2_use=$adaptor2;                 
                 $semaphore->down();        
                 if(exists($cutadapt_mirna->{$reads}))
                 {
                    $adaptor2_use=$cutadapt_mirna->{$reads};         
			         my $thread=threads->new(\&_run_cutadapt_mirna,$data_dir,$reads,$file_type,$read_suffix1,$read_suffix2,$read_type,$cut_dir,$semaphore,$adaptor1,$adaptor2_use,$phred);
			         $thread->detach();
			      }
			      else
			      {
					 my $thread=threads->new(\&_run_cutadapt,$data_dir,$reads,$file_type,$read_suffix1,$read_suffix2,$read_type,$cut_dir,$semaphore,$adaptor1,$adaptor2_use,$phred);
			         $thread->detach(); 
				   }
	             
         }
         sleep(3);
         &waitquit($max_threads,$semaphore);   ############ must
         print "run_cutadapt complete: ", &gettime;
}

sub _run_cutadapt
{
	         my ($data_dir,$reads,$file_type,$read_suffix1,$read_suffix2,$read_type,$cut_dir,$semaphore,$adaptor1,$adaptor2,$phred)=@_;
                 print "cutadapt: $reads, $read_type\n";
                       if($read_type eq "P")
                       {                     ##################
                               my $cmd;
                               my ($read1,$read2)=("$reads"."$read_suffix1".".$file_type","$reads"."$read_suffix2".".$file_type");
                              unless(-f "$cut_dir/$read1" && -f "$cut_dir/$read2")
                              {
								  unless(-f "$cut_dir/$read1.gz" && -f "$cut_dir/$read2.gz")
                                 {
                                    if(-f "$data_dir/$read1" && -f "$data_dir/$read2")
                                    {
                                             if($phred == 64)
                                             {
                                                    $cmd="cutadapt -m 20 -q 15 --quality-base=64 -a $adaptor1 -A $adaptor2 -o $cut_dir/$read1 -p $cut_dir/$read2 $data_dir/$read1 $data_dir/$read2";
											  }
											 else
											 {
													$cmd="cutadapt -m 20 -q 15  -a $adaptor1 -A $adaptor2 -o $cut_dir/$read1 -p $cut_dir/$read2 $data_dir/$read1 $data_dir/$read2";   
											 }
                                                    print $cmd,"\n"; system($cmd);
                                    }
                                    elsif((-f "$data_dir/$read1.gz") && -f ("$data_dir/$read2.gz") && (not -f "$data_dir/$read1") && (not -f "$data_dir/$read2"))
                                    {
                                             if($phred == 64)
                                             {
                                                    $cmd="cutadapt -m 20 -q 15 --quality-base=64 -a $adaptor1 -A $adaptor2 -o $cut_dir/$read1 -p $cut_dir/$read2 $data_dir/$read1.gz $data_dir/$read2.gz";
											 }
											 else
											 {
													$cmd="cutadapt -m 20 -q 15  -a $adaptor1 -A $adaptor2 -o $cut_dir/$read1 -p $cut_dir/$read2 $data_dir/$read1.gz $data_dir/$read2.gz";   
											 }
                                                    print $cmd,"\n"; system($cmd);
                                     }
                                    else
                                     {
                                                    print "can't find $read1 or $read1.gz under $data_dir\n";
                                     }
                                   #&get_length_distribution_plot($cut_dir,$read1);
                                   #&get_length_distribution_plot($cut_dir,$read2);
                                }
							}

                       }
                       else
                       {
						   my $cmd;
                           my $read1="$reads".".$file_type";
                           unless(-f "$cut_dir/$read1")
                              {
								  unless(-f "$cut_dir/$read1.gz")
                                 {
                                    if(-f "$data_dir/$read1")
                                    {
                                             if($phred == 64)
                                             {
                                                   $cmd="cutadapt -m 15 -q 15 --quality-base=64 -a $adaptor1 -o $cut_dir/$read1 $data_dir/$read1";
											  }
											 else
											 {
													$cmd="cutadapt -m 15 -q 15  -a $adaptor1 -o $cut_dir/$read1 $data_dir/$read1";   
											 }
                                                   print $cmd,"\n"; system($cmd);
                                    }
                                    elsif((-f "$data_dir/$read1.gz") && (not -f "$data_dir/$read1"))
                                    {
                                             if($phred == 64)
                                             {
                                                   $cmd="cutadapt -m 15 -q 15 --quality-base=64 -a $adaptor1 -o $cut_dir/$read1 $data_dir/$read1.gz";
											 }
											 else
											 {
													$cmd="cutadapt -m 15 -q 15 -a $adaptor1 -o $cut_dir/$read1 $data_dir/$read1.gz";   
											 }
                                                   print $cmd,"\n"; system($cmd);
                                     }
                                    else
                                     {
                                                   print "can't find $read1 or $read1.gz under $data_dir\n";
                                     }
                                   #&get_length_distribution_plot($cut_dir,$read1);
                                }
							}	
					}

                   $semaphore->up(); ##release signal
} #sub ciri_reads



sub _run_cutadapt_mirna
{
	         my ($data_dir,$reads,$file_type,$read_suffix1,$read_suffix2,$read_type,$cut_dir,$semaphore,$adaptor1,$adaptor2,$phred)=@_;
                 print "cutadapt: $reads, $read_type\n";
                       if($read_type eq "P")
                       {                     ##################
                               my $cmd;
                               my ($read1,$read2)=("$reads"."$read_suffix1".".$file_type","$reads"."$read_suffix2".".$file_type");
                              unless(-f "$cut_dir/$read1" && -f "$cut_dir/$read2")
                              {
								  unless(-f "$cut_dir/$read1.gz" && -f "$cut_dir/$read2.gz")
                                 {
                                    if(-f "$data_dir/$read1" && -f "$data_dir/$read2")
                                    {
                                             if($phred == 64)
                                             {
                                                   $cmd="cutadapt -m 20 -q 15 --quality-base=64 -a $adaptor1 -A $adaptor2 -g CTCGTATGCCGTCTTCTGCTTG -G TCGGACTGTAGAACTCTGAACGTGTAGATCTCGGTGGTCGCCGTATCATTAAAAAAAAA -G AGTTCTGATAACCCACTACCATCGGACCAGCC -o $cut_dir/$read1 -p $cut_dir/$read2 $data_dir/$read1 $data_dir/$read2";
											  }
											 else
											 {
													$cmd="cutadapt -m 20 -q 15  -a $adaptor1 -A $adaptor2 -g CTCGTATGCCGTCTTCTGCTTG -G TCGGACTGTAGAACTCTGAACGTGTAGATCTCGGTGGTCGCCGTATCATTAAAAAAAAA -G AGTTCTGATAACCCACTACCATCGGACCAGCC -o $cut_dir/$read1 -p $cut_dir/$read2 $data_dir/$read1 $data_dir/$read2";   
											 }
                                                   print $cmd,"\n"; system($cmd);
                                    }
                                    elsif((-f "$data_dir/$read1.gz") && -f ("$data_dir/$read2.gz") && (not -f "$data_dir/$read1") && (not -f "$data_dir/$read2"))
                                    {
                                             if($phred == 64)
                                             {
                                                   $cmd="cutadapt -m 20 -q 15 --quality-base=64 -a $adaptor1 -A $adaptor2 -g CTCGTATGCCGTCTTCTGCTTG -G TCGGACTGTAGAACTCTGAACGTGTAGATCTCGGTGGTCGCCGTATCATTAAAAAAAAA -G AGTTCTGATAACCCACTACCATCGGACCAGCC -o $cut_dir/$read1 -p $cut_dir/$read2 $data_dir/$read1.gz $data_dir/$read2.gz";
											 }
											 else
											 {
													$cmd="cutadapt -m 20 -q 15  -a $adaptor1 -A $adaptor2 -g CTCGTATGCCGTCTTCTGCTTG -G TCGGACTGTAGAACTCTGAACGTGTAGATCTCGGTGGTCGCCGTATCATTAAAAAAAAA -G AGTTCTGATAACCCACTACCATCGGACCAGCC -o $cut_dir/$read1 -p $cut_dir/$read2 $data_dir/$read1.gz $data_dir/$read2.gz";   
											 }
                                                    print $cmd,"\n"; system($cmd);
                                     }
                                    else
                                     {
                                                    print "can't find $read1 or $read1.gz under $data_dir\n";
                                     }
                                   #&get_length_distribution_plot($cut_dir,$read1);
                                   #&get_length_distribution_plot($cut_dir,$read2);
                                }
							}

                       }
                       else
                       {
						   my $cmd;
                           my $read1="$reads".".$file_type";
                           unless(-f "$cut_dir/$read1")
                              {
								  unless(-f "$cut_dir/$read1.gz")
                                 {
                                    if(-f "$data_dir/$read1")
                                    {
                                             if($phred == 64)
                                             {
                                                   $cmd="cutadapt -m 15 -q 15 --quality-base=64 -a $adaptor1 -g CTCGTATGCCGTCTTCTGCTTG -o $cut_dir/$read1 $data_dir/$read1";
											  }
											 else
											 {
													$cmd="cutadapt -m 15 -q 15  -a $adaptor1 -g CTCGTATGCCGTCTTCTGCTTG -o $cut_dir/$read1 $data_dir/$read1";   
											 }
                                                   print $cmd,"\n"; system($cmd);
                                    }
                                    elsif((-f "$data_dir/$read1.gz") && (not -f "$data_dir/$read1"))
                                    {
                                             if($phred == 64)
                                             {
                                                   $cmd="cutadapt -m 15 -q 15 --quality-base=64 -a $adaptor1 -g CTCGTATGCCGTCTTCTGCTTG -o $cut_dir/$read1 $data_dir/$read1.gz";
											 }
											 else
											 {
													$cmd="cutadapt -m 15 -q 15 -a $adaptor1 -g CTCGTATGCCGTCTTCTGCTTG -o $cut_dir/$read1 $data_dir/$read1.gz";   
											 }
                                                   print $cmd,"\n"; system($cmd);
                                     }
                                    else
                                     {
                                                   print "can't find $read1 or $read1.gz under $data_dir\n";
                                     }
                                   #&get_length_distribution_plot($cut_dir,$read1);
                                }
							}	
					}

                   $semaphore->up(); ##release signal
} #sub ciri_reads


                           ###  &get_length_distribution_plot($cut_dir,$fq);
sub get_length_distribution_plot
{
	my ($data_dir,$fq)=@_;
	my $mydir = getcwd();
	if(1)
	{
	     my $line;
	     open(INPUT, "$data_dir/$fq") or die "error (can't read $fq):$!";
	     open(OUTPUT, ">$data_dir/$fq.length") or die "error (can't create $fq.length):$!";
	     my %length=();
	     while($line=<INPUT>)
	     {
		     if($line =~ /^\@/)
		     {
		         $line=<INPUT>;
		         chomp $line;
		          $line=~ s/[\r\n]//g;
		         my $length = length($line);
		         if(exists($length{$length}))
		         {
				     $length{$length}++;
				     }
			     else
			     {
				     $length{$length}=1;
     				}
		         $line=<INPUT>;
		         $line=<INPUT>;
     	     } 
	     }
	     close INPUT;
     	foreach my $length(sort {$a <=> $b} keys %length)
	     {
		     print OUTPUT "$length\t$length{$length}\n";		
		     }	
	     close OUTPUT;	
     }
	&plot_histgram_R($data_dir,"$fq.length");
}
       # &plot_histgram_R("$data_dir/$fq.length");

sub plot_histgram_R
{	
my ($data_dir,$file) = @_;
my $mydir = getcwd();
print "plot_histgram_R $file\n";
open (RSCRIPT, ">plot_histgram_R_$file.R") or die "error(input1):$!";
print RSCRIPT "setwd(\"$mydir\"); 
mydata<-read.table(file=\'$data_dir/$file\',header=FALSE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE)
mydata<-mydata[order(mydata[,1]),]
png(\"$file.png\",height=4096,width=4096,units=\"px\",pointsize=12,res=300)
barplot(mydata[,2],names.arg=mydata[,1],main=\"$file \\nreads length distribution\",xlab=\"length\",ylab=\"reads number\",col =\"red\")
dev.off()
";
my $cmd="$R_dir/Rscript plot_histgram_R_$file.R >plot_histgram_R_$file.log";
print "$cmd\n"; system($cmd);	
}


sub waitquit
{
              my ($max_threads,$semaphore)=@_;
              print "Waiting to quit...\n";
	      my $num=0;
	      while($num<$max_threads)
	      {
	      	      $semaphore->down();
	      	      $num++;
	      	      print "$num thread quit...\n";
	      }
	      print "All $max_threads thread quit\n";
}


sub get_raw_line_count
{
	        # my $dir=shift;
	        my ($dir,$file_type,$read_suffix1)=@_;
	        print "\t\t\t\t\t\t\tget_raw_line_count   $dir\n";
	        my ($usr,$samples,$sampleindex,$sample_group) = &read_config();
            my $projectid=$usr->{'prj'};            
            my @files=keys %{$sampleindex};
            for(my $i=0;$i<=$#files;$i++)
            {
			    print "$files[$i]\n";
			} 	            
            my $line;
            my $raw_reads;            
            foreach my $file(@files)
            {
				if(-f "$dir/$file$read_suffix1.$file_type.line_count")
                {
                       open (INPUT1, "$dir/$file$read_suffix1.$file_type.line_count") or die "error(can't open $dir/$file$read_suffix1.$file_type.line_count):$!";
                       $line = <INPUT1>;
                       $line =~ /^\d+/;
                       $raw_reads->{$file}=$&/2;
                       close INPUT1;
                       print "get_raw_line_count $file\n";
                }
                elsif(-f "$dir/$file$read_suffix1.$file_type.th.log")
                {
                       open (INPUT1, "$dir/$file$read_suffix1.$file_type.th.log") or die "error(can't open $dir/$file$read_suffix1.$file_type.th.log):$!";
                       $line = <INPUT1>;
                       $line =~ /^\d+/;
                       $raw_reads->{$file}=$&/2;
                       close INPUT1;
                       print "get_raw_line_count $file\n";
                }
                elsif(-f "$dir/$file$read_suffix1.$file_type")
                {
					    $raw_reads->{$file}=0;
					    my $count = &get_line_count("$dir/$file$read_suffix1.$file_type");
					    $raw_reads->{$file}=$count/2;
					
				}
				elsif(-f "$dir/$file$read_suffix1.$file_type.gz")
                {
					   
					   $raw_reads->{$file}=0;
					   my $cmd = "gzip -dc $dir/$file$read_suffix1.$file_type.gz |wc -l >$dir/$file$read_suffix1.$file_type.line_count";
					   print "$cmd\n"; system($cmd);
					   if(-f "$dir/$file$read_suffix1.$file_type.line_count")
					   { 
					     open (INPUT1, "$dir/$file$read_suffix1.$file_type.line_count") or die "error(can't open $dir/$file$read_suffix1.$file_type.line_count):$!";
                         $line = <INPUT1>;
                         $line =~ /^\d+/;
                         $raw_reads->{$file}=$&/2;
                         close INPUT1;
				       } 
				}
				else
				{
					    print "can't find line_count: $dir/$file$read_suffix1.$file_type.line_count\n";
					    $raw_reads->{$file}=0;
				}				
			}
			return($raw_reads);		
}

sub get_raw_reads_number
{
	        # my $dir=shift;
	        my ($dir,$file_type,$read_suffix1,$reads_number)=@_;
	        print "\t\t\t\t\t\t\tget_raw_reads_number   $dir $file_type $read_suffix1\n";
	        my $line;
	        unless(defined($reads_number))
	        {
				$reads_number={};
			}
            my @files1=<$dir/*$read_suffix1.$file_type.gz>; 
	        my @files2=<$dir/*$read_suffix1.$file_type>; 
	        my @files3=<$dir/*$read_suffix1.$file_type.line_count>; 
               @files1=map{$_=basename($_)} @files1;
               @files2=map{$_=basename($_)} @files2;
               @files3=map{$_=basename($_)} @files3;
               chop @files1, foreach(1..3);   
               chop @files3, foreach(1..11);                          
               my @files =(@files2,@files1,@files3); 
               map{s/$read_suffix1\.$file_type$//}@files; 
               my @file1s;               
            foreach my $file(@files)
            {
				print "$file\n";
				if(-f "$dir/$file$read_suffix1.$file_type.th.log")
                {
                       open (INPUT1, "$dir/$file$read_suffix1.$file_type.th.log") or die "error(can't open $dir/$file$read_suffix1.$file_type.th.log):$!";
                       $line = <INPUT1>;
                       $line =~ /^\d+/;
                       $reads_number->{$file}=$&/2;
                       close INPUT1;
                       print "$file:$reads_number->{$file}\n";
                }
                elsif(-f "$dir/$file$read_suffix1.$file_type.line_count")
                {
                       open (INPUT1, "$dir/$file$read_suffix1.$file_type.line_count") or die "error(can't open $dir/$file$read_suffix1.$file_type.line_count):$!";
                       $line = <INPUT1>;
                       $line =~ /^\d+/;
                       $reads_number->{$file}=$&/2;
                       close INPUT1;
                       print "$file:$reads_number->{$file}\n";
                }
                elsif(-f "$dir/$file$read_suffix1.$file_type")
                {
					    push @file1s,$file;
					
				}
				elsif(-f "$dir/$file$read_suffix1.$file_type.gz")
                {
					   push @file1s,$file;					   
				}
				else
				{
					    $reads_number->{$file}=0;
				}				
			}
			my $semaphore=new Thread::Semaphore(10);
			foreach my $file (sort @file1s)
            {
                         print "non line_count $file!\n";
                         $semaphore->down();
	                     my $thread=threads->new(\&_get_line_count,"$dir/$file$read_suffix1.$file_type",$semaphore);
	                     $thread->detach();
             }
             &waitquit(10,$semaphore);
            foreach my $file (sort @file1s)
            {
                if(-f "$dir/$file$read_suffix1.$file_type.line_count")
                {
                       open (INPUT1, "$dir/$file$read_suffix1.$file_type.line_count") or die "error(can't open $dir/$file$read_suffix1.$file_type.line_count):$!";
                       $line = <INPUT1>;
                       $line =~ /^\d+/;
                       $reads_number->{$file}=$&/2;
                       print "$file:$reads_number->{$file}\n";
                       close INPUT1;
                }
             }
             return($reads_number);	
}

sub _get_line_count
{
	my ($file,$semaphore) = @_;
	my $count=0;
	if(-f $file)
	{
		print "creating $file.line_count................\n";
		unless(-f "$file.line_count")
		{	       
	       open(INPUT, "<$file") or die "error (can't read $file):$!";
	       $count++,while(<INPUT>);
	       close INPUT;
	       open(OUTPUT, ">$file.line_count") or die "error (can't create $file.line_count):$!";
	       print OUTPUT "$count\n";
	       close OUTPUT;
   		}
	}
	elsif(-f "$file.gz")
	{
		unless(-f "$file.line_count")
		{
			my $cmd = "gzip -dc $file.gz |wc -l >$file.line_count";
		     print "$cmd\n"; system($cmd);  
		}
	}		
	$semaphore->up();
}

sub get_line_count
{
	my $file = shift;
	my $count=0;
		if(-f "$file.line_count")
        {
                       my @array=stat("$file.line_count");
                       my $size = $array[7];
                       unless($size)
                       {
								unlink("$file.line_count");
								$count=&get_line_count($file);
						}						
                       open (INPUT1, "$file.line_count") or die "error(can't open $file.line_count):$!";
                       my $line = <INPUT1>;
                       $line =~ /^\d+/;
                       $count=$&;
                       close INPUT1;
                       print "get_raw_line_count $file\n";
         }
         else
         {		
	          open(INPUT, "<$file") or die "error (can't read $file):$!";
	          $count++,while(<INPUT>);
	          close INPUT;
	          open(OUTPUT, ">$file.line_count") or die "error (can't create $file.line_count):$!";
	          print OUTPUT "$count\n";
	          close OUTPUT;
		 }
	return($count);
}


sub get_q30_number
{
	        my ($file_type,$read_suffix1,$read_suffix2,$q30)=@_;	
	        print "\t\t\t\t\t\t\tget_q30_number\n";
	        my ($usr,$samples,$sampleindex,$sample_group) = &read_config();
            my $projectid=$usr->{'prj'};
             my @files=keys %{$sampleindex};
            for(my $i=0;$i<=$#files;$i++)
            {
			    print "$files[$i]\n";
			} 	            
            my $line;
            if(-f "q30.txt")
                {
                       open (INPUT1, "q30.txt") or die "error(can't open q30.txt):$!";
                       while($line = <INPUT1>)
                       {
						         chomp $line;		
						          $line=~ s/[\r\n]//g;				   
                                 my @terms=split(/\t/,$line);
                                    $terms[1]=~ /[\d\.]+/; 
                                    my $value=$&;
                                 $q30->{$terms[0]}=$value;
				        }
                       close INPUT1;
                }
            else
            {
				               my @q30files=<*.q30>;
                               open(OUTPUT, ">q30.txt") or die "error (can't create q30.txt):$!";
                               foreach my $file(@q30files)
                               {
                                  open(INPUT, "$file") or die "error (can't read $file):$!";
                                  my $line=<INPUT>;
                                  print OUTPUT "$line";
                                  close INPUT;
						       }
						       close OUTPUT;
						       
						open (INPUT1, "q30.txt") or die "error(can't open q30.txt):$!";
                       while($line = <INPUT1>)
                       {
						         chomp $line;	
						          $line=~ s/[\r\n]//g;					   
                                 my @terms=split(/\t/,$line);
                                    $terms[1]=~ /[\d\.]+/; 
                                    my $value=$&;
                                 $q30->{$terms[0]}=$value;
				        }
                       close INPUT1;
				
				}
            foreach my $file(@files)
            {
				if(exists($q30->{"$file"."$read_suffix1".".$file_type"}) && exists($q30->{"$file"."$read_suffix2".".$file_type"}))
				{
					$q30->{$file}=($q30->{"$file"."$read_suffix1".".$file_type"} + $q30->{"$file"."$read_suffix2".".$file_type"})/2;
				}
				else
				{
					$q30->{$file}=0;
					
				}				
			}            	
}

sub get_rRNA_ratio_number
{
	        my ($rRNA_ratio,$clean_reads)=@_;
	        my $mydir = getcwd();
	        print "\t\t\t\t\t\t\tget_rRNA_ratio_number\n";
	        my ($usr,$samples,$sampleindex,$sample_group) = &read_config();
            my $projectid=$usr->{'prj'};
            
            my @files=keys %{$sampleindex};
            for(my $i=0;$i<=$#files;$i++)
            {
			    print "$files[$i]\n";
			} 	            
            my $line;
            foreach my $file(@files)
            {
                ###(total c0 c1 cm s0 s1 sm rate)
                if(-f "$mydir/$file\_bowtie2_rRNA.log")
                {
                        my $ref_array = &read_bowtie2_log_new("$file\_bowtie2_rRNA.log"); ###(total c0 c1 cm d1 s0 s1 sm rate)
                        if(defined($ref_array->[8]))
                        {
                            if((not exists($clean_reads->{$file})) or ($clean_reads->{$file} == 0))
                            {
                              $clean_reads->{$file}=$ref_array->[0]*2;
                              print "clean reads: $file:$clean_reads->{$file}\n";
					        }
                            $rRNA_ratio->{$file}=$ref_array->[8];
                            print "rRNA_ratio:$file\t$ref_array->[8]\n";
					   }
					   else
					   {
						   if((not exists($clean_reads->{$file})) or ($clean_reads->{$file} == 0))
                            {
                              $clean_reads->{$file}=$ref_array->[0];
                              print "clean reads: $file:$clean_reads->{$file}\n";
					        }
                            $rRNA_ratio->{$file}=$ref_array->[4];
                            print "rRNA_ratio:$file\t$ref_array->[4]\n";
						}
                }
                elsif(-f "$mydir/${file}_rRNA/${file}Log.final.out")
                {
					    my $ref_array = &read_star_log("$mydir/$file/${file}Log.final.out");
                           if((not exists($clean_reads->{$file})) or ($clean_reads->{$file} == 0))
                            {
                              $clean_reads->{$file}=$ref_array->[0]*2;
                              print "clean reads: $file:$clean_reads->{$file}\n";
					        }
                        my $mapped=($ref_array->[1]+$ref_array->[2]+$ref_array->[3])*2;
                        $rRNA_ratio->{$file}=$mapped/$clean_reads->{$file};
                        print "rRNA_ratio:$file\t$rRNA_ratio->{$file}\n";
					
			     }
                else
                {
				      	$rRNA_ratio->{$file}=0;
				      	print ("can't find file $mydir/$file\_bowtie2_rRNA.log for $file\n");
				}
            }     
}
###SE(total unmpped mapped1 mappedm rate)



sub get_mapped_number
{
	        print "\t\t\t\t\t\t\tget_mapped_number\n";
	        my ($mapped,$map_ratio,$clean_reads)=@_;
	        my $mydir = getcwd();
	        my ($usr,$samples,$sampleindex,$sample_group) = &read_config();
            my $projectid=$usr->{'prj'};
            
            my @files=keys %{$sampleindex};
            for(my $i=0;$i<=$#files;$i++)
            {
			    print "$files[$i]\n";
			} 	            
            my $line;
            foreach my $file(@files)
            {
                if(not exists($mapped->{$file}))
                {
                    if(-f "$mydir/$file/${file}Log.final.out")
                    {
                      ###(total uniquely_mapped multi_mapped1 multi_mapped2 chimeric_reads)
                      my $ref_array = &read_star_log("$mydir/$file/${file}Log.final.out");
                         if((not exists($clean_reads->{$file})) or ($clean_reads->{$file} == 0))
                            {
                               $clean_reads->{$file}=$ref_array->[0]*2;
                               print "clean reads: $clean_reads->{$file}\n";
					          }
                         $mapped->{$file}=($ref_array->[1]+$ref_array->[2]+$ref_array->[3])*2;
                         print "$file\t$ref_array->[0]\t$mapped->{$file}\n";
                         $map_ratio->{$file}=$mapped->{$file}/$clean_reads->{$file};
                    }
                    elsif(-f "$file\_bowtie2.log" or -f "$file\_hisat2.log")
                    {
                        my $log_file="$file\_bowtie2.log";
                           $log_file="$file\_hisat2.log",if(-f "$file\_hisat2.log");                        
                             my $ref_array = &read_bowtie2_log_new($log_file);  ###(total c0 c1 cm d1 s0 s1 sm rate)
                        if(defined($ref_array->[8]))
                        {
                             if((not exists($clean_reads->{$file})) or ($clean_reads->{$file} == 0))
                              {
                               $clean_reads->{$file}=$ref_array->[0]*2;
                               print "clean reads: $clean_reads->{$file}\n";
					          }
                             $mapped->{$file}=$ref_array->[2]*2+$ref_array->[3]*2 +$ref_array->[4]*2+ $ref_array->[6] + $ref_array->[7];
                             $map_ratio->{$file}=$ref_array->[8]/100;
					     }
					     else       ###SE(total unmpped mapped1 mappedm rate)
					     {
							 if((not exists($clean_reads->{$file})) or ($clean_reads->{$file} == 0))
                              {
                               $clean_reads->{$file}=$ref_array->[0];
                               print "clean reads: $clean_reads->{$file}\n";
					          }
                             $mapped->{$file}=$ref_array->[2]+$ref_array->[3];
                             $map_ratio->{$file}=$ref_array->[4]/100;
						}
                    }
                    else
                    {					
    					print ("can't find file $mydir/$file/${file}Log.final.out or $file\_bowtie2.log\n");
    					$mapped->{$file}=0;
    					$map_ratio->{$file}=0;
					    # die("can't find file $mydir/$file/${file}Log.final.out");
				    }
			    }
			    elsif( exists($mapped->{$file}) && ($mapped->{$file} == 0))
			    {
					if(-f "$mydir/$file/${file}Log.final.out")
                    {
                      ###(total uniquely_mapped multi_mapped1 multi_mapped2 chimeric_reads)
                         my $ref_array = &read_star_log("$mydir/$file/${file}Log.final.out");
                            if((not exists($clean_reads->{$file})) or ($clean_reads->{$file} == 0))
                            {
                               $clean_reads->{$file}=$ref_array->[0]*2;
                               print "clean reads: $clean_reads->{$file}\n";
					          }
                         $mapped->{$file}=($ref_array->[1]+$ref_array->[2]+$ref_array->[3])*2;
                         print "$file\t$ref_array->[0]\t$mapped->{$file}\n";
                         $map_ratio->{$file}=$mapped->{$file}/$clean_reads->{$file};
                    }
                    elsif(-f "$file\_bowtie2.log" or -f "$file\_hisat2.log")
                    {
                        my $log_file="$file\_bowtie2.log";
                           $log_file="$file\_hisat2.log",if(-f "$file\_hisat2.log");                        
                             my $ref_array = &read_bowtie2_log_new($log_file);  ###(total c0 c1 cm d1 s0 s1 sm rate)
                        if(defined($ref_array->[8]))
                        {
                             if((not exists($clean_reads->{$file})) or ($clean_reads->{$file} == 0))
                              {
                               $clean_reads->{$file}=$ref_array->[0]*2;
                               print "clean reads: $clean_reads->{$file}\n";
					          }
                             $mapped->{$file}=$ref_array->[2]*2+$ref_array->[3]*2 +$ref_array->[4]*2+ $ref_array->[6] + $ref_array->[7];
                             $map_ratio->{$file}=$ref_array->[8]/100;
					     }
					     else       ###SE(total unmpped mapped1 mappedm rate)
					     {
							 if((not exists($clean_reads->{$file})) or ($clean_reads->{$file} == 0))
                              {
                               $clean_reads->{$file}=$ref_array->[0];
                               print "clean reads: $clean_reads->{$file}\n";
					          }
                             $mapped->{$file}=$ref_array->[2]+$ref_array->[3];
                             $map_ratio->{$file}=$ref_array->[4]/100;
						}
                    }                    
                    else
                    {					
    					print ("can't find file $mydir/$file/${file}Log.final.out or $file\_bowtie2.log\n");
    					$mapped->{$file}=0;
    					$map_ratio->{$file}=0;
					    # die("can't find file $mydir/$file/${file}Log.final.out");
				    }					
				}
			    else
			    {
					      print "get_mapped_number error\n";
					      if(exists($mapped->{$file}))
					      {
							   print "exists $file $mapped->{$file}\n";  
						   }
						   else
						   {
							   print "not exists mapped $file\n"; 
							}
					      
					
				}
            } 
}

sub get_clean_reads_number
{
	        print "\t\t\t\t\t\t\tget_clean_reads_number\n";
	        my ($mapped,$map_ratio,$clean_reads)=@_;
	        my $mydir = getcwd();
	        my ($usr,$samples,$sampleindex,$sample_group) = &read_config();
            my $projectid=$usr->{'prj'};
            
            my @files=keys %{$sampleindex};
            for(my $i=0;$i<=$#files;$i++)
            {
			    print "$files[$i]\n";
			} 	            
            my $line;
            foreach my $file(@files)
            {
                if((not exists($clean_reads->{$file})) or ($clean_reads->{$file} == 0))
                {
                    if(-f "$mydir/$file/${file}Log.final.out")
                    {
                      ###(total uniquely_mapped multi_mapped1 multi_mapped2 chimeric_reads)
                      my $ref_array = &read_star_log("$mydir/$file/${file}Log.final.out");
                         $clean_reads->{$file}=$ref_array->[0]*2;
                         print "$file\t$ref_array->[0]\n";
                         $mapped->{$file}=($ref_array->[1]+$ref_array->[2]+$ref_array->[3])*2;
                         print "$file\t$ref_array->[0]\t$mapped->{$file}\n";
                         $map_ratio->{$file}=$mapped->{$file}/$clean_reads->{$file};
                    }
                    elsif(-f "$file\_bowtie2.log")
                    {
                        my $ref_array = &read_bowtie2_log_new("$file\_bowtie2.log"); ###(total c0 c1 cm d1 s0 s1 sm rate)
                        $clean_reads->{$file}=$ref_array->[0]*2;
                        $mapped->{$file}=$ref_array->[2]*2 +$ref_array->[3]*2+ $ref_array->[4]*2 + $ref_array->[6] + $ref_array->[7];
                        $map_ratio->{$file}=$ref_array->[8]/100;
                    }
                    elsif(-f "$file\_hisat2.log")
                    {
                        my $ref_array = &read_bowtie2_log_new("$file\_hisat2.log"); ###(total c0 c1 cm d1 s0 s1 sm rate)
                        $clean_reads->{$file}=$ref_array->[0]*2;
                        $mapped->{$file}=$ref_array->[2]*2 +$ref_array->[3]*2+ $ref_array->[4]*2 + $ref_array->[6] + $ref_array->[7];
                        $map_ratio->{$file}=$ref_array->[8]/100;
                    }
                    else
                    {					
    					  print "can't find file $mydir/$file/${file}Log.final.out for clean reads\n";
    					  $clean_reads->{$file}=0;
					    # die("can't find file $mydir/$file/${file}Log.final.out");
				    }
			    }
			    else
			    {
					      print "clean_reads->$file already exists!\n";
					      if(exists($clean_reads->{$file}))
					      {
							 print "exists $file $clean_reads->{$file}\n";  
						   }
						   else
						   {
							   print "not exists mapped $file\n"; 
						   }					
				}
            }             
            	
}

sub get_nohup_time
{
        my $run_time=0;
        if(-f "nohup.out")
        {     
             print "\t\t\t\t\t\t\tget_nohup_time\n";
             open(INPUT, "nohup.out") or die "error (can't open nohup.out):$!";
                      my ($start_time,$end_time);
                      my $line;
                      while($line = <INPUT>)
                             {
                                my $reads_count=0;
                                if($line =~ /^start:\s+(\d+:\d+:\d+:\d+:\d+:\d+)$/)
                                {
                                        unless($start_time)
                                        {
											$start_time=$1;
											print "start time: $start_time\n";
											}
                                        
                                }
                                elsif($line =~ /^end:\s+(\d+:\d+:\d+:\d+:\d+:\d+)$/)
                                {
                                        $end_time=$1;
                                        print "end time: $end_time\n";
                                }
                             }
             close INPUT;
             $end_time = &gettime(),unless($end_time);
             $start_time = $end_time, unless($start_time);
             $run_time = &time_interval($start_time,$end_time);
		 }
	          return($run_time);
	}

sub get_duplicate_number
{
	        print "\t\t\t\t\t\t\tget_duplicate_number\n";
	        my ($file_type,$read_suffix1,$read_suffix2,$duplicate)=@_;	        
	        my ($usr,$samples,$sampleindex,$sample_group) = &read_config();
            my $projectid=$usr->{'prj'};
            
            my @files=keys %{$sampleindex};
            for(my $i=0;$i<=$#files;$i++)
            {
			    print "$files[$i]\n";
			} 	            
            my $line;
            if(-d "fastqc")
                {
					print "scanning fastqc files...................................\n";
                       for(my $i=0;$i<=$#files;$i++)
                       {
			               if(-f "fastqc/$files[$i]$read_suffix1\_fastqc.zip")
			               {
							    my $cmd = "unzip fastqc/$files[$i]$read_suffix1\_fastqc.zip -d fastqc";
							   print "$cmd\n";	   system($cmd),unless(-f "fastqc/$files[$i]$read_suffix1\_fastqc/fastqc_data.txt");
							   open (INPUT, "fastqc/$files[$i]$read_suffix1\_fastqc/fastqc_data.txt") or die "error(can't open fastqc/$files[$i]$read_suffix1\_fastqc/fastqc_data.txt):$!";							   
							   while($line = <INPUT>)
							   {								   
								   if($line =~ /Total Deduplicated Percentage\s+([\d\.]+)/)
								   {
									   $duplicate->{$files[$i]}->[0]=$1/100;
									   print "$files[$i] R1\t\t\t\t$duplicate->{$files[$i]}->[0]\n";									   
									}
								   
								}
								close INPUT;
						   }
						   else
						   {
							   $duplicate->{$files[$i]}->[0]=0;
							}
							   
						   if(-f "fastqc/$files[$i]$read_suffix2\_fastqc.zip")
			               {
							   my $cmd = "unzip fastqc/$files[$i]$read_suffix2\_fastqc.zip -d fastqc";
							   print "$cmd\n";	   system($cmd),unless(-f "fastqc/$files[$i]$read_suffix2\_fastqc/fastqc_data.txt");
							   open (INPUT, "fastqc/$files[$i]$read_suffix2\_fastqc/fastqc_data.txt") or die "error(can't open fastqc/$files[$i]$read_suffix2\_fastqc/fastqc_data.txt):$!";							   
							   while($line = <INPUT>)
							   {								   
								   if($line =~ /Total Deduplicated Percentage\s+([\d\.]+)/)
								   {
									   $duplicate->{$files[$i]}->[1]=$1/100;
									   print "$files[$i] R2\t\t\t\t$duplicate->{$files[$i]}->[1]\n";									   
									}
								   
								}
								close INPUT;
						   }
						   else
						   {
							   $duplicate->{$files[$i]}->[1]=0;
							}
			           } 
                }
}


sub fastqc_multiplex_cpu
{
      my ($data_dir,$file_type,$max_threads,$fastqc_dir) = @_;
      print "fastqc_multiplex_cpu start: ", &gettime();
      my $semaphore=new Thread::Semaphore($max_threads);
	  my @files1=<$data_dir/*.$file_type.gz>;
      my @files2=<$data_dir/*.$file_type>;
        @files1=map{$_=basename($_)} @files1;
        @files2=map{$_=basename($_)} @files2;
        chop @files1, foreach(1..3);
        my @files =(@files2,@files1);
        my %reads=();
      foreach my $reads(@files)
      {
      	    $reads{$reads}=1;
            print "$reads\n";
      }
      ########  multiplex cpu to calculate circRNA
         foreach my $reads(sort keys %reads)
         {
                 $semaphore->down();
	             my $thread=threads->new(\&fastqc,$data_dir,$reads,$fastqc_dir,$file_type,$semaphore);
	             $thread->detach();
         }
         &waitquit($max_threads,$semaphore);   ############ must
         print "fastqc_multiplex_cpu complete: ", &gettime;
}

sub  fastqc
{
                    my ($data_dir,$file,$fastqc_dir,$file_type,$semaphore) = @_;
                    my $name = $file;
                    $name =~ s/\.$file_type//;
                    
                    unless(-f "$data_dir/$file")
                    {
						$file.=".gz";
					}
                    my $cmd="/workplace/software/FastQC/fastqc -f fastq --noextract -contaminants /workplace/software/FastQC/Contaminants/contaminant_list.txt $data_dir/$file --outdir=$fastqc_dir/";                    
                    print "$cmd\n"; system($cmd), unless(-f "$fastqc_dir/$name\_fastqc.zip");
                    $semaphore->up(); ##release signal
}

sub fastq_screen_multiplex_cpu
{
      my ($data_dir,$file_type,$max_threads,$fastqscreen_dir) = @_;
      print "fastq_screen_multiplex_cpu start: ", &gettime();
      my $semaphore=new Thread::Semaphore($max_threads);
      my @files1=<$data_dir/*.$file_type.gz>;
      my @files2=<$data_dir/*.$file_type>;
        @files1=map{$_=basename($_)} @files1;
        @files2=map{$_=basename($_)} @files2;
        chop @files1, foreach(1..3);
        my @files =(@files2,@files1);
        my %reads=();
      foreach my $reads(@files)
      {
      	    $reads{$reads}=1;
            print "$reads\n";
      }
      ########  multiplex cpu to calculate circRNA
         foreach my $reads(sort keys %reads)
         {
                 $semaphore->down();
	             my $thread=threads->new(\&fastq_screen,$data_dir,$reads,$fastqscreen_dir,$file_type,$semaphore);
	             $thread->detach();
         }
         &waitquit($max_threads,$semaphore);   ############ must
         print "fastq_screen_multiplex_cpu complete: ", &gettime;
}

sub  fastq_screen
{
                    my ($data_dir,$file,$fastqscreen_dir,$file_type,$semaphore) = @_;
                    my $name = $file;
                    $name =~ s/\.$file_type//;
                    unless(-f "$data_dir/$file")
                    {
						$file .=".gz";
					}
                    my $cmd="fastq_screen $data_dir/$file --outdir=$fastqscreen_dir/";                    
                    print "$cmd\n"; system($cmd), unless(-f "$fastqscreen_dir/$name\_screen.png");
                    $semaphore->up(); ##release signal
}
# &head_multiplex_cpu($raw_dir,$file_type,12000000,10,$uncompress_dir),if($run_uncompress);
sub head_multiplex_cpu
{
      my ($data_dir,$file_type,$line_count,$max_threads,$uncompress_dir) = @_;
      print "head_multiplex_cpu start: ", &gettime();
      my $semaphore=new Thread::Semaphore($max_threads);
               my @files1=<$data_dir/*.$file_type.gz>;
               my @files2=<$data_dir/*.$file_type>;
               @files1=map{$_=basename($_)} @files1;
               @files2=map{$_=basename($_)} @files2;
               chop @files1, foreach(1..3);
               my @files =(@files2,@files1);
      ########  multiplex cpu to calculate circRNA
         foreach my $reads(sort @files)
         {
                     print "head_fastq:$data_dir,$reads,$line_count,$uncompress_dir,$semaphore\n";
                     $semaphore->down();
	             my $thread=threads->new(\&head_fastq,$data_dir,$reads,$line_count,$uncompress_dir,$semaphore);
	                 $thread->detach();
         }
                    &waitquit($max_threads,$semaphore);   ############ must
         print "uncompress_multiplex_cpu complete: ", &gettime;
}

sub  head_fastq
{
                    my ($data_dir,$file,$line_count,$uncompress_dir,$semaphore) = @_;                    
                    print "$file\n";
                    if(-f "$data_dir/$file.gz")
                    {
	                        my $cmd="gzip -dc $data_dir/$file.gz |head -$line_count>$uncompress_dir/$file";
                               print "$cmd\n"; system($cmd), unless(-f "$uncompress_dir/$file");
				     }
				    elsif(-f "$data_dir/$file")
                    {
						    my $cmd="head -$line_count $data_dir/$file>$uncompress_dir/$file";
                               print "$cmd\n"; system($cmd), unless(-f "$uncompress_dir/$file");
					}
					if(-f "$uncompress_dir/$file")
					{
                             my @array=stat("$uncompress_dir/$file");
                              my $size = $array[7];
                            unless($size)
                            {
								unlink("$uncompress_dir/$file");
								&head_fastq($data_dir,$file,$uncompress_dir,$semaphore);
							}
					}
                    $semaphore->up(); ##release signal
}

sub get_circRNA_statistics_dcc
{
            
            my ($raw_reads,$q30,$clean_reads,$rRNA_ratio,$mapped,$duplicate,$circ_count,$data_dir)=@_;
            my $mydir = getcwd();
            unless($data_dir)
            {
               $data_dir = "$mydir/uncompressed",if(-d "$mydir/uncompressed");
               $data_dir = "$mydir/tihuan",if(-d "$mydir/tihuan");
		    } 
		    print "\t\t\t\t\t\t\t\t\t\t\t\t\tget_circRNA_statistics_dcc\t\t\t$data_dir\n";  
		    my ($file_type,$read_type,$read_suffix1,$read_suffix2)= &read_file_type($data_dir);        
            my ($usr,$samples,$sampleindex,$sample_group) = &read_config();
            my $projectid=$usr->{'prj'};
            my ($taxid,$build)= &get_taxid($usr->{'spe'});
            my @files=keys %{$sampleindex};
            for(my $i=0;$i<=$#files;$i++)
            {
			    print "$files[$i]\n";
			} 	            
            my $line;
            my %map_ratio=(); 
            ## %raw_reads %q30  %clean_reads %rRNA_ratio  %mapped %map_ratio %duplicate
            &get_raw_reads_number($data_dir,$file_type,$read_suffix1,$read_suffix2,$raw_reads);
            &get_q30_number($file_type,$read_suffix1,$read_suffix2,$q30);
            &get_rRNA_ratio_number($rRNA_ratio,$clean_reads);
            &get_mapped_number($mapped,\%map_ratio,$clean_reads);
			&get_clean_reads_number($mapped,\%map_ratio,$clean_reads);
			&get_duplicate_number($file_type,$read_suffix1,$read_suffix2,$duplicate);
			my $run_time =&get_nohup_time();
                      
           print "\t\t\t\t\t\t\tinference circRNA counts\n";
           my $total_count=0;
           if(-f "CircCoordinates")
           { 
           open (INPUT1, "CircCoordinates") or die "error(can't open CircCoordinates):$!";
           open (INPUT2, "CircRNACount") or die "error(can't open CircRNACount):$!";
           # $line=<INPUT1>;
           $line=<INPUT2>;
           chomp $line;
            $line=~ s/[\r\n]//g;
           print "$line\n";
           my @terms=split(/\t/,$line);
           my $sample_num = @terms - 3;
           print "there are $sample_num samples!\n";
           
           my @samples = @terms[3..$#terms];
           chop(@samples), foreach(1..21);
           print "$_\n", foreach (@samples); 
           print "\n";          
           $line = join("\t",@samples);
           
          
                while($line=<INPUT1>)
                {
        	        chomp $line;
        	         $line=~ s/[\r\n]//g;
                        my @terms=split(/\t/,$line);
                        my $circRNA="$terms[0]:$terms[1]-$terms[2]$terms[5]";
                        $line=<INPUT2>;
                        chomp $line;
                         $line=~ s/[\r\n]//g;
                     @terms=split(/\t/,$line);
                     $total_count++;
                     my @data=@terms[3..$#terms];
                      my @count;
                       for(my $i=0;$i<$sample_num;$i++)
                       {
                         unless($data[$i] == 0)
                         {
                                  if(exists($circ_count->{$samples[$i]}))
                                  {
                                     $circ_count->{$samples[$i]}++;
                                  }
                                  else
                                  {
                                      $circ_count->{$samples[$i]}=1;
                                      print "$i\t$samples[$i]\n";
                                  }
                         }
                       }
                }
        	close INPUT1;
            close INPUT2;
            print "\n";  
		}          
            foreach (@files)
            {
				if(exists($circ_count->{$_}))
				{
				  print "$_\t$circ_count->{$_}\n";
			    }
			    else
			    {
					$circ_count->{$_}=0;
					print "$_\t$circ_count->{$_}\n";
					}
			}
            
            
            
            open(OUTPUT, ">$projectid\_inference.txt") or die "error (can't open $projectid\_inference.txt):$!";
            my @head=();
            push @head,'sampleID','sampleName','org','prepare','raw reads','q30','clean reads','read length','type','base(Gb)','methods','circRNAs','total_circRNA','time','rRNA','efficacious base(Gb)','mapped','mapped_ratio','fq1_dedup','fq2_dedup';
            my $head=join("\t",@head);
             print OUTPUT "$head\n";
             print "\nScanning *_circ_candidates.bed files........................\n";

            foreach my $sample (sort @files)
            {
                  my $org=$build;
                  my $experiment='circRNA-seq';
                  my $read_length=150;
                  my $seq_type="PE";
                  my $total_base= $raw_reads->{$sample}*150/1000000000;

                 # my $rRNA_ratio_value= $rRNA_ratio->{$reads}/100;

                  my $true_base=$clean_reads->{$sample}*150/1000000000*(100-$rRNA_ratio->{$sample})/100;
                     $map_ratio{$sample} = $mapped->{$sample}/$clean_reads->{$sample};
                  my @line=();  
                  my $d1=$duplicate->{$sample}->[0];
                  my $d2=$duplicate->{$sample}->[1];
                  print "$sample\n";
                  my $fq='';
                     foreach my $fastq(keys %$samples)  
                     {
						 $fq=$fastq,if($samples->{$fastq} eq $sample);
						 }
                     push @line,$fq,$sample,$org,$experiment,$raw_reads->{$sample},$q30->{$sample},$clean_reads->{$sample},
                     $read_length,$seq_type,$total_base,'DCC',$circ_count->{$sample},$total_count,$run_time,$rRNA_ratio->{$sample},$true_base,$mapped->{$sample},$map_ratio{$sample},$d1,$d2;
                     $line = join("\t",@line);
                     print OUTPUT "$line\n";
            }
            close OUTPUT;
            &txt2xlsx("$projectid\_inference");
}

sub get_circRNA_statistics_dcc_prepare
{
	        my ($original_dir,$file_type,$read_type,$read_suffix1,$read_suffix2,$raw_reads,$q30,$clean_reads,$rRNA_ratio,$mapped,$duplicate,$circ_count,$data_dir)=@_;
            my $mydir = getcwd();
            unless($data_dir)
            {
               $data_dir = "$mydir/uncompressed",if(-d "$mydir/uncompressed");
               $data_dir = "$mydir/tihuan",if(-d "$mydir/tihuan");
		    } 
		    print "\t\t\t\t\t\t\t\t\t\t\t\t\tget_circRNA_statistics_dcc_prepare\t\t\t$data_dir\n";  
            my ($usr,$samples,$sampleindex,$sample_group) = &read_config();
            my $projectid=$usr->{'prj'};
            my ($taxid,$build)= &get_taxid($usr->{'spe'});
            my @files=keys %{$sampleindex};
            for(my $i=0;$i<=$#files;$i++)
            {
			    print "$files[$i]\n";
			} 	            
            my $line;
            my %map_ratio=(); 
            ## %raw_reads %q30  %clean_reads %rRNA_ratio  %mapped %map_ratio %duplicate
            # &get_raw_reads_number($original_dir,$file_type,$read_suffix1,$read_suffix2,$raw_reads);
            &get_raw_reads_number($original_dir,$file_type,$read_suffix1,$raw_reads);
            &get_q30_number($file_type,$read_suffix1,$read_suffix2,$q30);            
            if(-d "$mydir/cutadapt")
            {
			        &get_raw_reads_number("$mydir/cutadapt",$file_type,$read_suffix1,$clean_reads);
		    }
		    else
		    {
				    &get_clean_reads_number($mapped,\%map_ratio,$clean_reads);
			}
			&get_rRNA_ratio_number($rRNA_ratio,$clean_reads);
            &get_mapped_number($mapped,\%map_ratio,$clean_reads);            
			&get_duplicate_number($file_type,$read_suffix1,$read_suffix2,$duplicate);
			my $run_time =&get_nohup_time();
			my $selected={};
			&get_raw_reads_number($data_dir,$file_type,$read_suffix1,$selected);
			foreach my $key (keys %$selected)
			{
				print "selected:$key\t$selected->{$key}\n";
				}
                      
           print "\t\t\t\t\t\t\tinference circRNA counts\n";
           my $total_count=0;
           if(-f "CircCoordinates")
           { 
           open (INPUT1, "CircCoordinates") or die "error(can't open CircCoordinates):$!";
           open (INPUT2, "CircRNACount") or die "error(can't open CircRNACount):$!";
           $line=<INPUT1>;
           $line=<INPUT2>;
           chomp $line;
            $line=~ s/[\r\n]//g;
           print "$line\n";
           my @terms=split(/\t/,$line);
           my $sample_num = @terms - 3;
           print "there are $sample_num samples!\n";
           
           my @samples = @terms[3..$#terms];
           chop(@samples), foreach(1..21);
           print "$_\n", foreach (@samples); 
           print "\n";          
           $line = join("\t",@samples);
           
          
                while($line=<INPUT1>)
                {
        	        chomp $line;
        	         $line=~ s/[\r\n]//g;
                        my @terms=split(/\t/,$line);
                        my $circRNA="$terms[0]:$terms[1]-$terms[2]$terms[5]";
                        $line=<INPUT2>;
                        chomp $line;
                         $line=~ s/[\r\n]//g;
                     @terms=split(/\t/,$line);
                     $total_count++;
                     my @data=@terms[3..$#terms];
                      my @count;
                       for(my $i=0;$i<$sample_num;$i++)
                       {
                         unless($data[$i] == 0)
                         {
                                  if(exists($circ_count->{$samples[$i]}))
                                  {
                                     $circ_count->{$samples[$i]}++;
                                  }
                                  else
                                  {
                                      $circ_count->{$samples[$i]}=1;
                                      print "$i\t$samples[$i]\n";
                                  }
                         }
                       }
                }
        	close INPUT1;
            close INPUT2;
            print "\n";  
		}          
            foreach (@files)
            {
				if(exists($circ_count->{$_}))
				{
				  print "$_\t$circ_count->{$_}\n";
			    }
			    else
			    {
					$circ_count->{$_}=0;
					print "$_\t$circ_count->{$_}\n";
					}
			} 
            open(OUTPUT, ">$projectid\_inference.txt") or die "error (can't open $projectid\_inference.txt):$!";
            my @head=();
            push @head,'sampleID','sampleName','q30','raw reads','total_base','selected','clean reads','clean ratio','rRNA','duplicates','mapped ratio','circRNAs';
            my $head=join("\t",@head);
             print OUTPUT "$head\n";
             print "\nScanning *_circ_candidates.bed files........................\n";

            foreach my $sample (sort @files)
            {
                     print "$sample:...................\n";
                     my $fq='';
                     foreach my $fastq(keys %$samples)  
                     {
						 $fq=$fastq,if($samples->{$fastq} eq $sample);
						 }
						 
                  my $experiment='circRNA-seq';
                  my $read_length=150;
                  my $seq_type="PE";
                  my $total_base;
                  
                  if(exists($raw_reads->{$fq}) && $raw_reads->{$fq}>0)
                  {
                         $total_base= $raw_reads->{$fq}*150/1000000000;
			      }
			      else
			      {
					  $raw_reads->{$fq}=$selected->{$sample};
					  $total_base= $raw_reads->{$fq}*150/1000000000;
				  }

                 # my $rRNA_ratio_value= $rRNA_ratio->{$reads}/100;
                 if(exists($clean_reads->{$sample}))
                 {
					 print "clean reads:$clean_reads->{$sample}\n";
				 }

                  my $true_base=$clean_reads->{$sample}*150/1000000000*(100-$rRNA_ratio->{$sample})/100;
                     $map_ratio{$sample}=0;
                     $map_ratio{$sample} = $mapped->{$sample}/$clean_reads->{$sample},if($clean_reads->{$sample});
                  my @line=();  
                  my $duplicates='NA';
                  if(exists($duplicate->{$sample}->[0]) && exists($duplicate->{$sample}->[1]))
                  {
					  $duplicates = 1-($duplicate->{$sample}->[0]+$duplicate->{$sample}->[1])/2;
					  }
                  print "$sample\n";
                  my $clean_ratio=0;
                  if(exists($selected->{$sample}))
                  {                      
                      if($selected->{$sample}>0)
                      {
                        $clean_ratio = $clean_reads->{$sample}/$selected->{$sample};
			          }
			      }
			      else
			      {
					  print "no selected $sample\n";
					  $selected->{$sample}=6000000;
					  $clean_ratio = $clean_reads->{$sample}/$selected->{$sample};
					  }
			      
                     push @line,$fq,$sample,$q30->{$sample}/100,$raw_reads->{$sample},$total_base,$selected->{$sample},$clean_reads->{$sample},$clean_ratio,$rRNA_ratio->{$sample}/100,
                     $duplicates,$map_ratio{$sample},$circ_count->{$sample};
                     $line = join("\t",@line);
                     print OUTPUT "$line\n";
            }
            close OUTPUT;
            &txt2xlsx("$projectid\_inference");
}

sub get_column_index
{
       my $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
       my @alphabet = split(//,$alphabet);
       my $column_index;
       my $tmp;
       for(my $i=0;$i<=$#alphabet;$i++)
       {
            $tmp=$i+1;
            $column_index->{$i+1}=$alphabet[$i];
            # print "alphabet:$tmp\t$column_index{$i+1}\n";
       }
       $tmp++;
       for(my $i=0;$i<=$#alphabet;$i++)
       {
          for(my $j=0;$j<=$#alphabet;$j++)
          {
             my $key="$alphabet[$i]$alphabet[$j]";
             $column_index->{$tmp}=$key;
             # print "alphabet:$tmp\t$column_index{$tmp}\n";
              $tmp++;
          }
       }
       return($column_index);
}


sub edgeR_de_table
{
   	my ($comparisons,$comparison,$file,$logcpm)=@_;
	my $samplesa=$comparisons->{$comparison}->{"samplesa"};
        my $samplesb=$comparisons->{$comparison}->{"samplesb"};
        my ($groupa,$groupb)=($comparisons->{$comparison}->{"a"},$comparisons->{$comparison}->{"b"});

    my $fc_threshold=$comparisons->{$comparison}->{"foldchange"};
    my $pv_threshold=$comparisons->{$comparison}->{"pvalue"};
    my $fdr_threshold=$comparisons->{$comparison}->{"fdr"};
    $fc_threshold=0,  unless($fc_threshold);
    $pv_threshold=1,  unless($pv_threshold);
    $fdr_threshold=1, unless($fdr_threshold);
    print "get_de_table:$comparison\t$fc_threshold\t$pv_threshold\t$fdr_threshold\n";
    my @samplesa=split(/, /,$samplesa);
    my @samplesb=split(/, /,$samplesb);
    open (INPUT, "$file.txt") or die "error($file.txt):$!";
    open (CPM, "$logcpm.txt") or die "error($logcpm.txt):$!";
    open (DE, "$file\_edgeR_$comparison.txt") or die "error($file\_edgeR_$comparison.txt):$!";
    open (OUTPUT, ">$file\_$comparison.txt") or die "error($file\_$comparison.txt):$!";
    open (OUTPUT1, ">$file\_$comparison\_all.txt") or die "error($file\_$comparison\_all.txt):$!";
    open (OUTPUT2, ">scatterplot_$file\_$comparison.txt") or die "error(scatterplot_$file\_$comparison.txt):$!";
    print OUTPUT2 "$groupa\t$groupb\n";
    my $line;
    my %de=();
    my %allde=();
    my %jr=();
    $line = <DE>;
    chomp $line;
     $line=~ s/[\r\n]//g;
    my @line=split(/\t/,$line);
    my $head0=$line."\tregulation";
    my ($fc_index,$pv_index,$fdr_index);
    for(my $i=0;$i<=$#line;$i++)
    {
		if($line[$i] eq 'logFC')
		{
			$fc_index=$i;
			}
		if($line[$i] eq 'PValue')
		{
			$pv_index=$i;
			}
		if($line[$i] eq 'FDR')
		{
			$fdr_index=$i;
			}
	}
      my ($up,$down);
    while($line=<DE>)
	{
		chomp $line;
		 $line=~ s/[\r\n]//g;
        my @line=split(/\t/,$line);
        my ($fc,$pv,$fdr)=@line[$fc_index,$pv_index,$fdr_index];
             if(abs($fc) >= log($fc_threshold)/log(2) && $pv <= $pv_threshold && $fdr<=$fdr_threshold)
              {

                if($fc>=0)
                {
				$up++;
                                $de{$line[0]}=$line."\tup";
        	}
	         else
        	{
				$down++;
                                $de{$line[0]}=$line."\tdown";
		}
	    }
            else
            {
                if($fc>=0)
                {
                                $allde{$line[0]}=$line."\tup";
        	}
	         else
        	{
                                $allde{$line[0]}=$line."\tdown";
		}
            }
	}
	close DE;
	my $count = keys %de;
	$count--;
	print "there are $count de circRNA in $comparison\n";
	print "there are $up upregulated, $down down-regulated circRNAs in $comparison\n";
    $line = <INPUT>;
    chomp $line;
     $line=~ s/[\r\n]//g;
    my @heads=split(/\t/,$line);
    my @columns;
    my @groupa_idx;
    my @groupb_idx;
    for(my $i=0;$i<=$#samplesa;$i++)
    {
		for(my $j=0;$j<=$#heads;$j++)
		{
			if($samplesa[$i] eq $heads[$j])
			   {
				 push @columns,$j;
				}
		}
	}
	for(my $i=0;$i<=$#samplesb;$i++)
    {
		for(my $j=0;$j<=$#heads;$j++)
		{
			if($samplesb[$i] eq $heads[$j])
			   {
				 push @columns,$j;
				}
		}
	}

        $line = <CPM>;
        chomp $line;
         $line=~ s/[\r\n]//g;
        my @cpm_heads=split(/\t/,$line);
        my @columns_cpm;
    for(my $i=0;$i<=$#samplesa;$i++)
    {
		for(my $j=0;$j<=$#cpm_heads;$j++)
		{
			if($samplesa[$i] eq $cpm_heads[$j])
			   {
				                 push @columns_cpm,$j;
                                 push @groupa_idx,$j;
				}
		}
	}
	for(my $i=0;$i<=$#samplesb;$i++)
    {
		for(my $j=0;$j<=$#cpm_heads;$j++)
		{
			if($samplesb[$i] eq $cpm_heads[$j])
			   {
				 push @columns_cpm,$j;
                                 push @groupb_idx,$j;
				}
		}
	}
        my $head = join("\t",$head0,@heads[@columns],@cpm_heads[@columns_cpm]);
	print OUTPUT "$head\n";
        print OUTPUT1 "$head\n";
        my %cpm=();
        while($line=<CPM>)
	{
           chomp $line;
            $line=~ s/[\r\n]//g;
           my @line=split(/\t/,$line);
             $cpm{$line[0]} = join("\t",@line[@columns_cpm]);
             my @gba=@line[@groupa_idx];
             my @gbb=@line[@groupb_idx];
             my $meana = &average_array(\@gba);
             my $meanb = &average_array(\@gbb);
             print OUTPUT2 "$meana\t$meanb\n";
        }
	while($line=<INPUT>)
	{
	   chomp $line;
	    $line=~ s/[\r\n]//g;
           my @line=split(/\t/,$line);
              $jr{$line[0]} = join("\t",@line[@columns]);
	}
    close INPUT;
    close CPM;
        foreach my $circ (keys %de)
        {
          $line = join("\t",$de{$circ},$jr{$circ},$cpm{$circ});
          print OUTPUT "$line\n";
          print OUTPUT1 "$line\n";

        }
        foreach my $circ (keys %allde)
        {
          $line = join("\t",$allde{$circ},$jr{$circ},$cpm{$circ});
          print OUTPUT1 "$line\n";
        }
    close OUTPUT;
    close OUTPUT1;
    close OUTPUT2;
      my $cmd="python $scatter_py scatterplot_$file\_$comparison.txt";
      print "$cmd\n";
      system($cmd);
}







sub get_comparisons
{
   my $cfg=shift;
   my $comparisons;
   my $count = keys %{$cfg->{'2_group_unpaired_comparison'}};
   $count = int($count/6);
   if($count)
   {
       for(my $i=1;$i<=$count;$i++)
       {
	        my $groupa = $cfg->{'2_group_unpaired_comparison'}->{"2_group_unpaired_comparison_$i\_groupA_name"};
	        my $groupb = $cfg->{'2_group_unpaired_comparison'}->{"2_group_unpaired_comparison_$i\_groupB_name"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"sort"}=$i;
	        $comparisons->{"$groupa\_vs_$groupb"}->{"type"}="2_group_unpaired_comparison";
	        $comparisons->{"$groupa\_vs_$groupb"}->{"a"}=$groupa;
	        $comparisons->{"$groupa\_vs_$groupb"}->{"b"}=$groupb;
	        $comparisons->{"$groupa\_vs_$groupb"}->{"samplesa"}=$cfg->{'2_group_unpaired_comparison'}->{"2_group_unpaired_comparison_$i\_groupA_samples"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"samplesb"}=$cfg->{'2_group_unpaired_comparison'}->{"2_group_unpaired_comparison_$i\_groupB_samples"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"foldchange"}=$cfg->{'2_group_unpaired_comparison'}->{"2_group_unpaired_comparison_$i\_FC"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"pvalue"}=$cfg->{'2_group_unpaired_comparison'}->{"2_group_unpaired_comparison_$i\_PValue"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"fdr"}=$cfg->{'2_group_unpaired_comparison'}->{"2_group_unpaired_comparison_$i\_fdr"};
                my @sas=split(/,/,$comparisons->{"$groupa\_vs_$groupb"}->{"samplesa"});
                my @sbs=split(/,/,$comparisons->{"$groupa\_vs_$groupb"}->{"samplesb"});
                my $n1=@sas;
                my $n2=@sbs;
                foreach my $sample(@sas)
                {
                    $sample=~s/^\s+//g;
                    $sample=~s/\s+$//g;
                    $comparisons->{"$groupa\_vs_$groupb"}->{"group"}->{$sample}=$groupa;
                }
                foreach my $sample(@sbs)
                {
                    $sample=~s/^\s+//g;
                    $sample=~s/\s+$//g;
                    $comparisons->{"$groupa\_vs_$groupb"}->{"group"}->{$sample}=$groupb;
                }
                $comparisons->{"$groupa\_vs_$groupb"}->{"sn"}=$n1+$n2;
	        &create_unpaired_group_comparison_design_file($comparisons,"$groupa\_vs_$groupb");
	    }

   }
   $count = keys %{$cfg->{'2_group_paired_comparison'}};
   $count = int($count/6);
   if($count)
   {
       for(my $i=1;$i<=$count;$i++)
       {
	        my $groupa = $cfg->{'2_group_paired_comparison'}->{"2_group_paired_comparison_$i\_groupA_name"};
	        my $groupb = $cfg->{'2_group_paired_comparison'}->{"2_group_paired_comparison_$i\_groupB_name"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"type"}="2_group_paired_comparison";
	        $comparisons->{"$groupa\_vs_$groupb"}->{"sort"}=$i;
	        $comparisons->{"$groupa\_vs_$groupb"}->{"a"}=$groupa;
	        $comparisons->{"$groupa\_vs_$groupb"}->{"b"}=$groupb;
	        $comparisons->{"$groupa\_vs_$groupb"}->{"samplesa"}=$cfg->{'2_group_paired_comparison'}->{"2_group_paired_comparison_$i\_groupA_samples"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"samplesb"}=$cfg->{'2_group_paired_comparison'}->{"2_group_paired_comparison_$i\_groupB_samples"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"foldchange"}=$cfg->{'2_group_paired_comparison'}->{"2_group_paired_comparison_$i\_FC"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"pvalue"}=$cfg->{'2_group_paired_comparison'}->{"2_group_paired_comparison_$i\_PValue"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"fdr"}=$cfg->{'2_group_paired_comparison'}->{"2_group_paired_comparison_$i\_fdr"};
                my @sas=split(/,/,$comparisons->{"$groupa\_vs_$groupb"}->{"samplesa"});
                my @sbs=split(/,/,$comparisons->{"$groupa\_vs_$groupb"}->{"samplesb"});
                my $n1=@sas;
                my $n2=@sbs;
                foreach my $sample(@sas)
                {
                    $sample=~s/^\s+//g;
                    $sample=~s/\s+$//g;
                    $comparisons->{"$groupa\_vs_$groupb"}->{"group"}->{$sample}=$groupa;
                }
                foreach my $sample(@sbs)
                {
                    $sample=~s/^\s+//g;
                    $sample=~s/\s+$//g;
                    $comparisons->{"$groupa\_vs_$groupb"}->{"group"}->{$sample}=$groupb;
                }
                $comparisons->{"$groupa\_vs_$groupb"}->{"sn"}=$n1+$n2;
	        &create_paired_group_comparison_design_file($comparisons,"$groupa\_vs_$groupb");
	    }
   }

   $count = keys %{$cfg->{'2_sample_comparison'}};
   $count = int($count/2);
   if($count)
   {
       print "there are 3 2_sample_comparison!\n";
       for(my $i=1;$i<=$count;$i++)
       {
	        my $samples = $cfg->{'2_sample_comparison'}->{"2_sample_comparison_$i"};
	        my @sas=split(/,/,$samples);
	           for(my $j=0; $j<=1; $j++)
                {
                    $sas[$j]=~s/^\s+//g;
                    $sas[$j]=~s/\s+$//g;
				}
			my $comparison="$sas[0]\_vs_$sas[1]";
			$comparisons->{$comparison}->{"sort"}=$i;
	        my $fc = $cfg->{'2_sample_comparison'}->{"2_sample_comparison_$i\_fc"};
	        $comparisons->{$comparison}->{"type"}="2_sample_comparison";
	        $comparisons->{$comparison}->{"samplesa"}=$sas[0];
	        $comparisons->{$comparison}->{"samplesb"}=$sas[1];
	        $comparisons->{$comparison}->{"a"}=$sas[0];
	        $comparisons->{$comparison}->{"b"}=$sas[1];
                $comparisons->{$comparison}->{"group"}->{$sas[0]}=$sas[0];
                $comparisons->{$comparison}->{"group"}->{$sas[1]}=$sas[1];

            $comparisons->{$comparison}->{"sn"}=2;
            $comparisons->{$comparison}->{"foldchange"}=$fc;
	        &create_2_sample_comparison_design_file($comparisons,$comparison);
	    }
   }

   $count = keys %{$cfg->{'1_sample_vs_1_group_comparison'}};
   $count = int($count/5);
   if($count)
   {
       for(my $i=1;$i<=$count;$i++)
       {
	        my $groupa = $cfg->{'1_sample_vs_1_group_comparison'}->{"1_sample_vs_one_group_comparison_$i\_sample_name"};
	        my $groupb = $cfg->{'1_sample_vs_1_group_comparison'}->{"1_sample_vs_one_group_comparison_$i\_group_name"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"type"}="1_sample_vs_1_group_comparison";
	        $comparisons->{"$groupa\_vs_$groupb"}->{"sort"}=$i;
	        $comparisons->{"$groupa\_vs_$groupb"}->{"a"}=$groupa;
	        $comparisons->{"$groupa\_vs_$groupb"}->{"b"}=$groupb;
	        $comparisons->{"$groupa\_vs_$groupb"}->{"samplesa"}=$cfg->{'1_sample_vs_1_group_comparison'}->{"1_sample_vs_one_group_comparison_$i\_sample"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"samplesb"}=$cfg->{'1_sample_vs_1_group_comparison'}->{"1_sample_vs_one_group_comparison_$i\_group"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"foldchange"}=$cfg->{'1_sample_vs_1_group_comparison'}->{"1_sample_vs_one_group_comparison_$i\_FC"};
                $comparisons->{"$groupa\_vs_$groupb"}->{"pvalue"}=$cfg->{'1_sample_vs_1_group_comparison'}->{"1_sample_vs_one_group_comparison_$i\_PValue"};

                my @sas=split(/,/,$comparisons->{"$groupa\_vs_$groupb"}->{"samplesa"});
                my @sbs=split(/,/,$comparisons->{"$groupa\_vs_$groupb"}->{"samplesb"});
                my $n1=@sas;
                my $n2=@sbs;
                foreach my $sample(@sas)
                {
                    $sample=~s/^\s+//g;
                    $sample=~s/\s+$//g;
                    $comparisons->{"$groupa\_vs_$groupb"}->{"group"}->{$sample}=$groupa;
                }
                foreach my $sample(@sbs)
                {
                    $sample=~s/^\s+//g;
                    $sample=~s/\s+$//g;
                    $comparisons->{"$groupa\_vs_$groupb"}->{"group"}->{$sample}=$groupb;
                }
                $comparisons->{"$groupa\_vs_$groupb"}->{"sn"}=$n1+$n2;
	            &create_unpaired_group_comparison_design_file($comparisons,"$groupa\_vs_$groupb");
	    }
   }

   $count = keys %{$cfg->{'1_group_vs_1_sample_comparison'}};
   $count = int($count/5);
   if($count)
   {
       for(my $i=1;$i<=$count;$i++)
       {
                my $groupa = $cfg->{'1_group_vs_1_sample_comparison'}->{"1_group_vs_one_sample_comparison_$i\_group_name"};
                my $groupb = $cfg->{'1_group_vs_1_sample_comparison'}->{"1_group_vs_one_sample_comparison_$i\_sample_name"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"type"}="1_group_vs_1_sample_comparison";
	        $comparisons->{"$groupa\_vs_$groupb"}->{"sort"}=$i;
	        $comparisons->{"$groupa\_vs_$groupb"}->{"a"}=$groupa;
	        $comparisons->{"$groupa\_vs_$groupb"}->{"b"}=$groupb;
	        $comparisons->{"$groupa\_vs_$groupb"}->{"samplesa"}=$cfg->{'1_group_vs_1_sample_comparison'}->{"1_group_vs_one_sample_comparison_$i\_group"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"samplesb"}=$cfg->{'1_group_vs_1_sample_comparison'}->{"1_group_vs_one_sample_comparison_$i\_sample"};
	        $comparisons->{"$groupa\_vs_$groupb"}->{"foldchange"}=$cfg->{'1_group_vs_1_sample_comparison'}->{"1_group_vs_one_sample_comparison_$i\_FC"};
                $comparisons->{"$groupa\_vs_$groupb"}->{"pvalue"}=$cfg->{'1_group_vs_1_sample_comparison'}->{"1_group_vs_one_sample_comparison_$i\_PValue"};

                my @sas=split(/,/,$comparisons->{"$groupa\_vs_$groupb"}->{"samplesa"});
                my @sbs=split(/,/,$comparisons->{"$groupa\_vs_$groupb"}->{"samplesb"});
                my $n1=@sas;
                my $n2=@sbs;
                foreach my $sample(@sas)
                {
                    $sample=~s/^\s+//g;
                    $sample=~s/\s+$//g;
                    $comparisons->{"$groupa\_vs_$groupb"}->{"group"}->{$sample}=$groupa;
                }
                foreach my $sample(@sbs)
                {
                    $sample=~s/^\s+//g;
                    $sample=~s/\s+$//g;
                    $comparisons->{"$groupa\_vs_$groupb"}->{"group"}->{$sample}=$groupb;
                }
                $comparisons->{"$groupa\_vs_$groupb"}->{"sn"}=$n1+$n2;
	            &create_unpaired_group_comparison_design_file($comparisons,"$groupa\_vs_$groupb");
	    }
   }

    foreach my $comparison(keys %{$comparisons})
    {
		    print "comparison list: $comparison\n";
    }
    return($comparisons);
}



sub create_profiling_design_file
{
       my ($usr,$samples,$sampleindex,$sample_group) = &read_config();
       open (OUTPUT, ">all_design.txt") or die "error(all_design.txt):$!";
       print OUTPUT "sampleID\tgroup\n";
       my %hash=();
       foreach my $sample(sort {$sampleindex->{$a}<=>$sampleindex->{$b}} keys %{$sampleindex})
       {                         
                         print OUTPUT "$sample\t$sample_group->{$sample}\n";
       }
       close OUTPUT;
}

sub create_2_sample_comparison_design_file
{
my ($comparisons,$comparison)=@_;
open (OUTPUT, ">$comparison\_design.txt") or die "error($comparison\_design.txt):$!";
print OUTPUT "sampleID\tgroup\n";
		   my $name=$comparisons->{$comparison}->{"samplesa"};
		   print OUTPUT "$name\tg2\n";
		      $name=$comparisons->{$comparison}->{"samplesb"};
		   print OUTPUT "$name\tg1\n";

close OUTPUT;
}

sub create_unpaired_group_comparison_design_file
{
       my ($comparisons,$comparison)=@_;
       my ($usr,$samples,$sampleindex,$sample_group) = &read_config();
       open (OUTPUT, ">$comparison\_design.txt") or die "error($comparison\_design.txt):$!";
       print OUTPUT "sampleID\tgroup\n";
       my %hash=();
       my $samplesa=$comparisons->{$comparison}->{"samplesa"};
       my $samplesb=$comparisons->{$comparison}->{"samplesb"};
       my @samplesa=split(/, /,$samplesa);
       my ($groupa,$groupb)=($comparisons->{$comparison}->{"a"},$comparisons->{$comparison}->{"b"});
       foreach my $sample(@samplesa)
       {
		   $hash{$sample}=1;
		   print OUTPUT "$sample\tA\n";

		   }
       my @samplesb=split(/, /,$samplesb);
       foreach my $sample(@samplesb)
       {
		   $hash{$sample}=1;
		   print OUTPUT "$sample\tB\n";

		   }

       foreach my $sample(keys %{$samples})
       {
		  unless(exists($hash{$samples->{$sample}}))
		  {
			 print OUTPUT "$samples->{$sample}\tother\n";
		   }
	   }
       close OUTPUT;
}

sub create_paired_group_comparison_design_file
{
       my ($comparisons,$comparison)=@_;
       my ($usr,$samples,$sampleindex,$sample_group) = &read_config();
       open (OUTPUT, ">$comparison\_design.txt") or die "error($comparison\_design.txt):$!";
       print OUTPUT "sampleID\tgroup\tpatient\n";
       my %hash=();
       my $samplesa=$comparisons->{$comparison}->{"samplesa"};
       my $samplesb=$comparisons->{$comparison}->{"samplesb"};
       my @samplesa=split(/, /,$samplesa);
       my ($groupa,$groupb)=($comparisons->{$comparison}->{"a"},$comparisons->{$comparison}->{"b"});

       my $patient=1;
       foreach my $sample(@samplesa)
       {
		   $hash{$sample}=1;
		   print OUTPUT "$sample\t2\t$patient\n";
		   $patient++;
		   }
       my @samplesb=split(/, /,$samplesb);
       $patient=1;
       foreach my $sample(@samplesb)
       {
		   $hash{$sample}=1;
		   print OUTPUT "$sample\t1\t$patient\n";
		   $patient++;
	    }

       foreach my $sample(keys %{$samples})
       {
		  unless(exists($hash{$samples->{$sample}}))
		  {
			 #print OUTPUT "$samples->{$sample}\tother\t$patient\n";
		   }
	   }
       close OUTPUT;
}

sub edgeR_1sample_vs_group_comparison_fun
{
	my ($mydata,$mydesign,$comparisons,$comparison,$dispersion)=@_;
    my ($groupa,$groupb)=($comparisons->{$comparison}->{"a"},$comparisons->{$comparison}->{"b"});
    my $mydir = getcwd();
open FILE1, ">edgeR_1sample_vs_group_comparison_fun.R";
print FILE1 "
setwd(\"$mydir\")
library(limma)
library(edgeR)
mydata<-read.table(file='$mydata.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE,row.names=1)
grouptable<-read.table(file='$mydesign.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE)
samples<-colnames(mydata)
sn<-length(samples)
samples<-samples[1:length(samples)]
group<-samples
group<-as.character(group)
for (i in 1:length(samples))
{
	for(j in 1:length(grouptable[,1]))
	{
		if( samples[i] == grouptable[j,1])
		{
			group[i]<-as.character(grouptable[j,2])
			}
		}
	}
samples
group
group<-factor(group)
y<-DGEList(counts=mydata,group=group)
y<-calcNormFactors(y)#默认为TMM标准化
logcpm<-cpm(y,log=TRUE)
write.table(logcpm, file='$mydata\_edgeR_logcpm.txt', sep=\"\\t\", quote=FALSE)
design <- model.matrix(~group)
rownames(design) <- colnames(y)
y\$common.dispersion <- $dispersion
et<-exactTest(y)
out<- topTags(et, n=Inf, adjust.method='BH')
output<-out\$table
write.table(output, file='$mydata\_edgeR_$comparison.txt', sep=\"\\t\", quote=FALSE)
summary(de<-decideTestsDGE(et))
detags<-rownames(y)[as.logical(de)]
png('$mydata\_plotSmear_$comparison.png',height=4096,width=4096,units='px',pointsize=12,res=300)
plotSmear(et, de.tags=detags)
abline(h=c(-1,1),col='blue')
dev.off()
";
close FILE1;
 my $cmd= "$R_dir/Rscript edgeR_1sample_vs_group_comparison_fun.R";  #deal_psl.sql文件将psl表中的的数据取出，分析，导出similar0.5的lncRNA列表。 
 print "$cmd\n"; system($cmd);
 &Rtable_add_head("$mydata\_edgeR_$comparison",'CircRNAID');
 rename("$mydata\_edgeR_$comparison\_added.txt","$mydata\_edgeR_$comparison.txt");
 &Rtable_add_head("$mydata\_edgeR_logcpm",'CircRNAID');
 rename("$mydata\_edgeR_logcpm_added.txt","$mydata\_edgeR_logcpm.txt");
print "successful edgeR_fun!\n";
}


sub edgeR_2sample_comparison_fun
{
	my ($mydata,$mydesign,$comparisons,$comparison,$dispersion)=@_;
    my ($groupa,$groupb)=($comparisons->{$comparison}->{"a"},$comparisons->{$comparison}->{"b"});
    my $mydir = getcwd();
open FILE1, ">edgeR_2sample_comparison_fun.R";
print FILE1 "
setwd(\"$mydir\")
library(limma)
library(edgeR)
mydata<-read.table(file='$mydata.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE,row.names=1)
grouptable<-read.table(file='$mydesign.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE)
samples<-colnames(mydata)
sn<-length(samples)
samples<-samples[1:length(samples)]
group<-samples
group<-as.character(group)
for (i in 1:length(samples))
{
	for(j in 1:length(grouptable[,1]))
	{
		if( samples[i] == grouptable[j,1])
		{
			group[i]<-as.character(grouptable[j,2])
			}
		}
	}
samples
group
group<-factor(group)
y<-DGEList(counts=mydata,group=group)
y<-calcNormFactors(y)#默认为TMM标准化
logcpm<-cpm(y,log=TRUE)
write.table(logcpm, file='$mydata\_edgeR_$comparison\_logcpm.txt', sep=\"\\t\", quote=FALSE)
design <- model.matrix(~group)
rownames(design) <- colnames(y)
y\$common.dispersion <- $dispersion
et<-exactTest(y)
out<- topTags(et, n=Inf, adjust.method='BH')
output<-out\$table
write.table(output, file='$mydata\_edgeR_$comparison.txt', sep=\"\\t\", quote=FALSE)
summary(de<-decideTestsDGE(et))
detags<-rownames(y)[as.logical(de)]
png('$mydata\_plotSmear_$comparison.png',height=4096,width=4096,units='px',pointsize=12,res=300)
plotSmear(et, de.tags=detags)
abline(h=c(-1,1),col='blue')
dev.off()
";
close FILE1;
 my $cmd= "$R_dir/Rscript edgeR_2sample_comparison_fun.R";  #deal_psl.sql文件将psl表中的的数据取出，分析，导出similar0.5的lncRNA列表。
 print "$cmd\n"; system($cmd);
 &Rtable_add_head("$mydata\_edgeR_$comparison",'CircRNAID');
 rename("$mydata\_edgeR_$comparison\_added.txt","$mydata\_edgeR_$comparison.txt");
 &Rtable_add_head("$mydata\_edgeR_$comparison\_logcpm",'CircRNAID');
 rename("$mydata\_edgeR_logcpm_added.txt","$mydata\_edgeR_logcpm.txt");
print "successful edgeR_fun!\n";
}


sub edgeR_logcpm
{
	my ($mydata,$mydesign)=@_;
	my $mydir = getcwd();
open FILE1, ">edgeR_logcpm.R";
print FILE1 "
setwd(\"$mydir\")
library(limma)
library(edgeR)
mydata<-read.table(file='$mydata.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE,row.names=1)
grouptable<-read.table(file='$mydesign.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE)
samples<-colnames(mydata)
sn<-length(samples)
samples<-samples[1:length(samples)]
group<-samples
group<-as.character(group)
for (i in 1:length(samples))
{
	for(j in 1:length(grouptable[,1]))
	{
		if( samples[i] == grouptable[j,1])
		{
			group[i]<-as.character(grouptable[j,2])
			}
		}
	}
samples
group
group<-factor(group)
y<-DGEList(counts=mydata,group=group)
y<-calcNormFactors(y)#默认为TMM标准化
logcpm<-cpm(y,log=TRUE)
write.table(logcpm, file=\"$mydata\_edgeR_all_logcpm.txt\", sep=\"\\t\", quote=FALSE)
if(sn>2)
{
png(\"$mydata\_plotMDS\_all.png\",height=4096,width=4096,units=\"px\",pointsize=12,res=300)
plotMDS(y)
dev.off()
}
";
close FILE1;
my $cmd="$R_dir/Rscript edgeR_logcpm.R";
 print "$cmd\n"; system($cmd);  #deal_psl.sql文件将psl表中的的数据取出，分析，导出similar0.5的lncRNA列表。
 &Rtable_add_head("$mydata\_edgeR_all_logcpm",'CircRNAID');
 rename("$mydata\_edgeR_all_logcpm_added.txt","$mydata\_edgeR_all_logcpm.txt");
 print "successful edgeR_fun!\n";
}


sub edgeR_glm_qlf_fun
{
	my ($mydata,$mydesign,$comparisons,$comparison)=@_;
    my ($groupa,$groupb)=($comparisons->{$comparison}->{"a"},$comparisons->{$comparison}->{"b"});
    my $mydir = getcwd();
    print "edgeR_glm_qlf_fun:$comparison\n";
open FILE1, ">edgeR_glm_qlf_fun.R";
print FILE1 "
setwd(\"$mydir\")
library(limma)
library(edgeR)
mydata<-read.table(file='$mydata.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE,row.names=1)
grouptable<-read.table(file='$mydesign.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE)
samples<-colnames(mydata)
sn<-length(samples)
samples<-samples[1:length(samples)]
group<-samples
group<-as.character(group)
for (i in 1:length(samples))
{
	for(j in 1:length(grouptable[,1]))
	{
		if( samples[i] == grouptable[j,1])
		{
			group[i]<-as.character(grouptable[j,2])
			}
		}
	}
samples
group
group<-factor(group)
y<-DGEList(counts=mydata,group=group)
y<-calcNormFactors(y)#默认为TMM标准化
logcpm<-cpm(y,log=TRUE)
write.table(logcpm, file=\"$mydata\_edgeR_logcpm.txt\", sep=\"\\t\", quote=FALSE)
png(\"$mydata\_plotMDS\_$comparison.png\",height=4096,width=4096,units=\"px\",pointsize=12,res=300)
plotMDS(y)
dev.off()
design <- model.matrix(~0+group)
colnames(design) <- levels(group)
y <- estimateDisp(y,design)
BvsA <- makeContrasts(A-B, levels=design)
fit <- glmQLFit(y, design, robust=TRUE)
qlf <- glmLRT(fit, contrast=BvsA)
out<- topTags(qlf, n=Inf, adjust.method=\"BH\")
output<-out\$table
write.table(output, file=\"$mydata\_edgeR_$comparison.txt\", sep=\"\\t\", quote=FALSE)
summary(de<-decideTestsDGE(qlf))
detags<-rownames(y)[as.logical(de)]
png(\"$mydata\_plotSmear_$comparison.png\",height=4096,width=4096,units=\"px\",pointsize=12,res=300)
plotSmear(qlf, de.tags=detags)
abline(h=c(-1,1),col='blue')
dev.off()
";
close FILE1;
 my $cmd= "$R_dir/Rscript edgeR_glm_qlf_fun.R";  
 print "$cmd\n"; system($cmd);
 #deal_psl.sql文件将psl表中的的数据取出，分析，导出similar0.5的lncRNA列表。
 &Rtable_add_head("$mydata\_edgeR_$comparison",'CircRNAID');
 rename("$mydata\_edgeR_$comparison\_added.txt","$mydata\_edgeR_$comparison.txt");
 &Rtable_add_head("$mydata\_edgeR_logcpm",'CircRNAID');
 rename("$mydata\_edgeR_logcpm_added.txt","$mydata\_edgeR_logcpm.txt");
print "successful edgeR_fun!\n";
}

sub edgeR_glm_lr_fun
{
	my ($mydata,$mydesign,$comparisons,$comparison)=@_;
	my $mydir = getcwd();
    my ($groupa,$groupb)=($comparisons->{$comparison}->{"a"},$comparisons->{$comparison}->{"b"});
open FILE1, ">edgeR_glm_lr_fun.R";
print FILE1 "
setwd(\"$mydir\")
library(limma)
library(edgeR)
mydata<-read.table(file='$mydata.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE,row.names=1)
grouptable<-read.table(file='$mydesign.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE)
samples<-colnames(mydata)
sn<-length(samples)
samples<-samples[1:length(samples)]
group<-samples
group<-as.character(group)
for (i in 1:length(samples))
{
	for(j in 1:length(grouptable[,1]))
	{
		if( samples[i] == grouptable[j,1])
		{
			group[i]<-as.character(grouptable[j,2])
			}
		}
	}
samples
group
group<-factor(group)
y<-DGEList(counts=mydata,group=group)
y<-calcNormFactors(y)#默认为TMM标准化
logcpm<-cpm(y,log=TRUE)
write.table(logcpm, file=\"$mydata\_edgeR_$comparison\_logcpm.txt\", sep=\"\\t\", quote=FALSE)
png(\"$mydata\_plotMDS\_$comparison.png\",height=4096,width=4096,units=\"px\",pointsize=12,res=300)
plotMDS(y)
dev.off()
design <- model.matrix(~0+group)
colnames(design) <- levels(group)
y <- estimateDisp(y,design)
BvsA <- makeContrasts($groupb-$groupa, levels=design)
fit <- glmFit(y, design)
lrt <- glmLRT(fit, contrast=BvsA)
out<- topTags(lrt, n=Inf, adjust.method=\"BH\")
output<-out\$table
write.table(output, file=\"$mydata\_edgeR_$comparison.txt\", sep=\"\\t\", quote=FALSE)
summary(de<-decideTestsDGE(lrt))
detags<-rownames(y)[as.logical(de)]
png(\"$mydata\_plotSmear_$comparison.png\",height=4096,width=4096,units=\"px\",pointsize=12,res=300)
plotSmear(lrt, de.tags=detags)
abline(h=c(-1,1),col='blue')
dev.off()
";
close FILE1;
 my $cmd="$R_dir/Rscript edgeR_glm_lr_fun.R";  #deal_psl.sql文件将psl表中的的数据取出，分析，导出similar0.5的lncRNA列表。 
 print "$cmd\n"; system($cmd);
 &Rtable_add_head("$mydata\_edgeR_$comparison",'CircRNAID');
 rename("$mydata\_edgeR_$comparison\_added.txt","$mydata\_edgeR_$comparison.txt");
 &Rtable_add_head("$mydata\_edgeR_$comparison\_logcpm",'CircRNAID');
 rename("$mydata\_edgeR_$comparison\_logcpm_added.txt","$mydata\_edgeR_$comparison\_logcpm.txt");
print "successful edgeR_fun!\n";
}


sub get_comparison_data
{
	my ($mydata,$comparisons,$comparison) =@_;
	my @sas=split(/,/,$comparisons->{$comparison}->{"samplesa"});
    my @sbs=split(/,/,$comparisons->{$comparison}->{"samplesb"});
    my %samples_used=();
    foreach (@sas)
    {
		s/^\s+//g;
        s/\s+$//g;
		$samples_used{$_}=1;
		}
    foreach (@sbs)
    {
		s/^\s+//g;
        s/\s+$//g;
		$samples_used{$_}=1;
		}
    my @index=();
    open(INPUT, "$mydata.txt") or die "error ($mydata.txt):$!";
    open(OUTPUT, ">$comparison\_data.txt") or die "error ($comparison.txt):$!";
    my $line=<INPUT>;
    chomp $line;
    $line=~s/[\r\n]//g;
    my @title=split(/\t/,$line);
    for(my $i=0;$i<=$#title;$i++)
    {
		if(exists($samples_used{$title[$i]}))
		{
			push @index,$i;
		}
	}
	print OUTPUT join("\t",$title[0],@title[@index]),"\n";
	while($line=<INPUT>)
	{
		chomp $line;
        $line=~s/[\r\n]//g;
         my @title=split(/\t/,$line);
         my @data=@title[@index];
         my $sum=0;
         $sum+=$_,foreach(@data);
         print OUTPUT join("\t",$title[0],@title[@index]),"\n",if($sum);
		}
	close INPUT;
	close OUTPUT;	
}


sub edgeR_glm_lr_paired_fun
{
	my ($mydata,$mydesign,$comparisons,$comparison)=@_;
	my $mydir = getcwd();
    my ($groupa,$groupb)=($comparisons->{$comparison}->{"a"},$comparisons->{$comparison}->{"b"});
    &get_comparison_data($mydata,$comparisons,$comparison);    
open FILE1, ">edgeR_glm_lr_paired_fun.R";
print FILE1 "
setwd(\"$mydir\")
library(limma)
library(edgeR)
mydata<-read.table(file='$comparison\_data.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE,row.names=1)
grouptable<-read.table(file='$mydesign.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE)
samples<-colnames(mydata)
sn<-length(samples)
samples<-samples[1:length(samples)]
group<-samples
group<-as.character(group)
patient<-samples
patient<-as.character(patient)
for (i in 1:length(samples))
{
	for(j in 1:length(grouptable[,1]))
	{
		if( samples[i] == grouptable[j,1])
		{
			group[i]<-as.character(grouptable[j,2])
			patient[i]<-as.character(grouptable[j,3])
			}
		}
	}
group<-factor(group)
patient<-factor(patient)
y<-DGEList(counts=mydata,group=group)
y<-calcNormFactors(y)#默认为TMM标准化
logcpm<-cpm(y,log=TRUE)
write.table(logcpm, file=\"$mydata\_edgeR_$comparison\_logcpm.txt\", sep=\"\\t\", quote=FALSE)
png(\"$mydata\_plotMDS\_$comparison.png\",height=4096,width=4096,units=\"px\",pointsize=12,res=300)
plotMDS(y)
dev.off()
design <- model.matrix(~patient+group)
rownames(design) <- colnames(y)
y <- estimateDisp(y,design)
fit <- glmFit(y, design)
lrt <- glmLRT(fit)
out<- topTags(lrt, n=Inf, adjust.method=\"BH\")
output<-out\$table
write.table(output, file=\"$mydata\_edgeR_$comparison.txt\", sep=\"\\t\", quote=FALSE)
summary(de<-decideTestsDGE(lrt))
detags<-rownames(y)[as.logical(de)]
png(\"$mydata\_plotSmear_$comparison.png\",height=4096,width=4096,units=\"px\",pointsize=12,res=300)
plotSmear(lrt, de.tags=detags)
abline(h=c(-1,1),col='blue')
dev.off()
";
close FILE1;
 my $cmd= "$R_dir/Rscript edgeR_glm_lr_paired_fun.R";  #deal_psl.sql文件将psl表中的的数据取出，分析，导出similar0.5的lncRNA列表。
 print "$cmd\n"; system($cmd);
 &Rtable_add_head("$mydata\_edgeR_$comparison",'CircRNAID');
 rename("$mydata\_edgeR_$comparison\_added.txt","$mydata\_edgeR_$comparison.txt");
 &Rtable_add_head("$mydata\_edgeR_$comparison\_logcpm",'CircRNAID');
 rename("$mydata\_edgeR_$comparison\_logcpm_added.txt","$mydata\_edgeR_$comparison\_logcpm.txt");
print "successful edgeR_fun!\n";
}


sub edgeR_classic_fun
{
	my ($mydata,$mydesign,$comparisons,$comparison)=@_;
	my $mydir = getcwd();
    my ($groupa,$groupb)=($comparisons->{$comparison}->{"a"},$comparisons->{$comparison}->{"b"});
open FILE1, ">edgeR_classic_fun.R";
print FILE1 "
setwd(\"$mydir\")
library(limma)
library(edgeR)
mydata<-read.table(file='$mydata.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE,row.names=1)
grouptable<-read.table(file='$mydesign.txt',header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE)
samples<-colnames(mydata)
sn<-length(samples)
samples<-samples[1:length(samples)]
group<-samples
group<-as.character(group)
for (i in 1:length(samples))
{
	for(j in 1:length(grouptable[,1]))
	{
		if( samples[i] == grouptable[j,1])
		{
			group[i]<-as.character(grouptable[j,2])
			}
		}
	}
samples
group
group<-factor(group)
y<-DGEList(counts=mydata,group=group)
y<-calcNormFactors(y)#默认为TMM标准化
logcpm<-cpm(y,log=TRUE)
write.table(logcpm, file=\"$mydata\_edgeR_logcpm.txt\", sep=\"\\t\", quote=FALSE)
png(\"$mydata\_plotMDS\_$comparison.png\",height=4096,width=4096,units=\"px\",pointsize=12,res=300)
plotMDS(y)
dev.off()
design <- model.matrix(~0+group)
colnames(design) <- levels(group)
y <- estimateDisp(y,design)
et<-exactTest(y,pair=c(\"$groupb\",\"$groupa\"))
out<- topTags(et, n=Inf, adjust.method=\"BH\")
output<-out\$table
write.table(output, file=\"$mydata\_edgeR_$comparison.txt\", sep=\"\\t\", quote=FALSE)
summary(de<-decideTestsDGE(et))
detags<-rownames(y)[as.logical(de)]
png(\"$mydata\_plotSmear_$comparison.png\",height=4096,width=4096,units=\"px\",pointsize=12,res=300)
plotSmear(et, de.tags=detags)
abline(h=c(-1,1),col='blue')
dev.off()
";
close FILE1;
 my $cmd= "$R_dir/Rscript edgeR_classic_fun.R";  #deal_psl.sql文件将psl表中的的数据取出，分析，导出similar0.5的lncRNA列表。
 print "$cmd\n"; system($cmd);
 &Rtable_add_head("$mydata\_edgeR_$comparison",'CircRNAID');
 rename("$mydata\_edgeR_$comparison\_added.txt","$mydata\_edgeR_$comparison.txt");
 &Rtable_add_head("$mydata\_edgeR_logcpm",'CircRNAID');
 rename("$mydata\_edgeR_logcpm_added.txt","$mydata\_edgeR_logcpm.txt");
print "successful edgeR_fun!\n";
}


sub Rtable_add_head
{
    my ($filename,$head)=@_;
    open (INPUT, "$filename.txt") or die "error(can't open $filename):$!";
    open (OUTPUT, ">$filename\_added.txt") or die "error(can't open $filename):$!";
    my $line;
    $line=<INPUT>;
    print OUTPUT "$head\t$line";
    print OUTPUT $line, while($line=<INPUT>);
    close INPUT;
    close OUTPUT;
}
sub get_edgeR_de_report
{
       my ($cfg,$count_table)=@_;
       my $mydir = getcwd();
       print "get_edgeR_de_report:\n";
       my ($usr,$samples,$sampleindex,$sample_group) = &read_config();
       my $sn=keys %{$sampleindex};
       my $junction_reads="junction_reads";
       if($count_table)
       {
		   $junction_reads=$count_table;
		   }
       my $projectid=$cfg->{'user_infomation'}->{'projcet_number'};
       my $heatmap_cmd=$cfg->{'heatmap'}->{'heatmap_operation_code'};
       my $annotation="$projectid\_CircRNAs_annotation_updated";
        my $anno_col=11;
        my $species=$cfg->{'user_infomation'}->{'species'};
       if(lc($species) eq 'human')
       {
          $annotation.="_a";
          $anno_col++;
       }
        my $logcpm="$junction_reads\_edgeR_all_logcpm";
       copy("$myperl_dir/$volcano_py","$mydir/$volcano_py"),unless(-f "$mydir/$volcano_py");
       copy("$myperl_dir/$scatter_py","$mydir/$scatter_py"),unless(-f "$mydir/$scatter_py");
       if(1)
       {
         &create_profiling_design_file();
         &edgeR_logcpm($junction_reads,"all_design");
         &add_column("$junction_reads\_edgeR_all_logcpm",$junction_reads,0,0,[1..$sn],"$junction_reads\_edgeR_all_logcpm_temp",1);
         &add_column($annotation,"$junction_reads\_edgeR_all_logcpm_temp",3,0,[0..2,5..$anno_col],"$projectid\_profiling",1);
         &edgeR_profiling_excel("$projectid\_profiling",$sn,$species);
         &edger_boxplot($logcpm);
         &edger_violin_plot($logcpm);
       }

       if(1)
       {
               my $comparisons = &get_comparisons($cfg);
               foreach my $comparison(sort {$comparisons->{$a}->{'sort'} <=> $comparisons->{$b}->{'sort'}} keys %{$comparisons})
               {
                          if($comparisons->{$comparison}->{"type"} eq "2_group_unpaired_comparison")
                          {
                               &edgeR_glm_qlf_fun($junction_reads,"$comparison\_design",$comparisons,$comparison);           ### recommended algorithm
                              # &edgeR_glm_lr_fun("junction_reads","$comparison\_design",$comparison);           ### alternative algorithm 1
		      	              # &edgeR_classic_fun("junction_reads","$comparison\_design",$comparison);          ### alternative algorithm 2
                          }
                          elsif($comparisons->{$comparison}->{"type"} eq "2_group_paired_comparison")
                          {
							  ########### 配对比较不能有非本次比较的样本。
                              &edgeR_glm_lr_paired_fun($junction_reads,"$comparison\_design",$comparisons,$comparison);
                              
                          }
                          elsif($comparisons->{$comparison}->{"type"} eq "2_sample_comparison")
                          {
                              &edgeR_2sample_comparison_fun($junction_reads,"$comparison\_design",$comparisons,$comparison,1.46);
                          }
                          elsif($comparisons->{$comparison}->{"type"} eq "1_sample_vs_1_group_comparison")
                          {
                              &edgeR_glm_qlf_fun("$junction_reads","$comparison\_design",$comparisons,$comparison);
                          }
                          elsif($comparisons->{$comparison}->{"type"} eq "1_group_vs_1_sample_comparison")
                          {
                              &edgeR_glm_qlf_fun("$junction_reads","$comparison\_design",$comparisons,$comparison);
                          }

                            &edger_volcano_plot($junction_reads,$comparison);
                            &edgeR_de_table($comparisons,$comparison,$junction_reads,$logcpm); 
                            &add_column($annotation,"$junction_reads\_$comparison",3,0,[0..2,5..$anno_col],"$junction_reads\_$comparison\_annotation",1);
                            &add_column($annotation,"$junction_reads\_$comparison\_all",3,0,[0..2,5..$anno_col],"$junction_reads\_$comparison\_all_annotation",1);
	        }
                   &edger_de_excel($junction_reads,'de',$comparisons,$species);
                   &edger_de_excel($junction_reads,'all',$comparisons,$species);
                   &edger_heatmap($heatmap_cmd);
        }
        print "\n\n\n\t\t\t\t\t\t\tscript completed!\n";
 }


sub edger_heatmap
{
   my $heatmap_cmd=shift;
   my $mydir = getcwd();
   mkdir "heatmap", unless(-d "heatmap");	
   mkdir "heatmap/expr_sig",unless(-d "heatmap/expr_sig");
   my $cmd = "cp $myperl_dir/cluster.pl heatmap/cluster.pl";
   print "$cmd\n";
   system($cmd);
   $cmd = "cp heatmap*.txt heatmap/";
   print "$cmd\n";
   system($cmd);
   chdir("$mydir/heatmap");
   print "$heatmap_cmd\n";
   system($heatmap_cmd);
   
   $cmd = "cp expr_sig/*.tif ../";
   print "$cmd\n";
   system($cmd);    
   chdir $mydir;
}


sub average_array
{
    my $ref=shift;
    my $sum=0;
      foreach my $num1 ( @{$ref} )
      {
          $sum +=  $num1;
      }
      my $count = scalar(@{$ref});
      my $ave =$sum/$count;
      return $ave;
 }

sub edger_volcano_plot
{
    my ($junction_reads,$comparison)=@_;
    my $input="$junction_reads\_edgeR_$comparison";
       &obtain_edgeR_volcano_data($junction_reads,$comparison);
    my $cmd="python $volcano_py volcano_plot_$comparison.txt 0.05 2.0 $comparison";
       print "$cmd\n"; system($cmd);
}

sub obtain_edgeR_volcano_data
{
    my ($junction_reads,$comparison)=@_;
    my $input="$junction_reads\_edgeR_$comparison";
     open (INPUT, "$input.txt") or die "error($input.txt):$!";
     open (OUTPUT, ">volcano_plot_$comparison.txt") or die "error($input\_without_rn.txt):$!";
     my $line;
     $line=<INPUT>;
     chomp $line;
      $line=~ s/[\r\n]//g;
     my ($pv_idx,$fc_idx,$regu_idx);
     my @head=split(/\t/,$line);
     for(my $i=0;$i<=$#head;$i++)
     {
         $pv_idx=$i,if($head[$i] eq 'PValue');
         $fc_idx=$i,if($head[$i] eq 'logFC');
     }
     $line = join("\t",@head[$pv_idx,$fc_idx]);
     print OUTPUT "$line\n";
     while($line=<INPUT>)
     {
            chomp $line;
             $line=~ s/[\r\n]//g;
         my @line=split(/\t/,$line);
         my $regu='up';
            $regu='down',if($line[$fc_idx] < 0);
            $line = join("\t",@line[$pv_idx,$fc_idx]);
            print OUTPUT "$line\n";
     }
     close INPUT;
     close OUTPUT;
}

sub obtain_boxplot_data
{
    my $logcpm=shift;
     open (INPUT, "$logcpm.txt") or die "error($logcpm.txt):$!";
     open (BP, ">$logcpm\_without_rn.txt") or die "error($logcpm\_without_rn.txt):$!";
     my $line;
     while($line=<INPUT>)
     {
            chomp $line;
             $line=~ s/[\r\n]//g;
         my @line=split(/\t/,$line);
            $line = join("\t",@line[1..$#line]);
            print BP "$line\n";
     }
     close INPUT;
     close BP;
}
sub edger_boxplot
{
  my $logcpm=shift;
     &obtain_boxplot_data($logcpm);
     &ggplot2_boxplot("$logcpm\_without_rn");
}
sub edger_violin_plot
{
  my $logcpm=shift;
     &obtain_boxplot_data($logcpm);
     &ggplot2_violin("$logcpm\_without_rn");
}

sub ggplot2_violin
{
	my $mydata=shift;
	my $mydir = getcwd();
open FILE1, ">ggplot2_violin.R";
print FILE1 "
setwd(\"$mydir\")
library(ggplot2)
library(reshape2)
mydata<-read.table(file=\"$mydata.txt\",header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE)
mydata1<-melt(mydata)
colnames(mydata1)[1]<-'group'
min<-min(mydata1\$value)
mydata1<-mydata1[mydata1\$value>min,]
png(\"violin_$mydata.png\",height=4096,width=4096,units=\"px\",pointsize=12,res=300)
plot <- ggplot(mydata1, aes(x=group, y=value,fill=group),size=20)
plot<-plot + geom_violin(trim=T, position=position_dodge(1))+geom_boxplot(width=0.05, fill=\"white\")
plot<-plot+theme(panel.border=element_rect(linetype='solid',fill=NA,colour = \"black\"),axis.title.x=element_blank(),axis.title.y=element_text(size=20,color='black'),axis.text.x =element_text(size=20,color='black'), axis.text.y=element_text(size=20,color='black'),legend.position=\"none\")
plot<-plot+labs(y = \"logCPM\")
plot
dev.off()
";
close FILE1;
my $cmd= "$R_dir/Rscript ggplot2_violin.R";
print "$cmd\n"; system($cmd);

print "successful edgeR_fun!\n";
}

sub ggplot2_boxplot
{
	my $mydata=shift;
	my $mydir = getcwd();
open FILE1, ">ggplot2_boxplot.R";
print FILE1 "
setwd(\"$mydir\")
library(ggplot2)
library(reshape2)
mydata<-read.table(file=\"$mydata.txt\",header=TRUE,check.names=FALSE,sep=\"\\t\",blank.lines.skip = TRUE)
mydata1<-melt(mydata)
colnames(mydata1)[1]<-'group'
min<-min(mydata1\$value)
mydata1<-mydata1[mydata1\$value>min,]
png(\"boxplot_$mydata.png\",height=4096,width=4096,units=\"px\",pointsize=12,res=300)
plot <- ggplot(mydata1, aes(x=group,y=value,fill=group),size=20) + geom_boxplot()
plot<-plot+theme(panel.border=element_rect(linetype='solid',fill=NA,colour = \"black\"),axis.title.x=element_blank(),axis.title.y=element_text(size=20,color='black'),axis.text.x =element_text(size=20,color='black'), axis.text.y=element_text(size=20,color='black'),legend.position=\"none\")
plot<-plot+labs(y = \"logCPM\")
plot
plot
dev.off()
";
close FILE1;
my $cmd= "$R_dir/Rscript ggplot2_boxplot.R";
print "$cmd\n"; system($cmd);

print "successful edgeR_fun!\n";
}


sub edger_de_excel
{

        my ($junction_reads,$mode,$comparisons,$species)=@_;
        my $output="Differentially Expressed circRNAs.xlsx";
        if($mode eq 'all')
        {
            $output='All Comparisons.xlsx';
            print "\t\t\t\t\t\t\tedger_de_excel_all\n";
        }
        else
        {
            print "\t\t\t\t\t\t\tedger_de_excel\n";
        }
        my $workbook = Excel::Writer::XLSX->new($output);
        foreach my $comparison(sort {$comparisons->{$a}->{'sort'} <=> $comparisons->{$b}->{'sort'}} keys %{$comparisons})
        {
             my $type=$comparisons->{$comparison}->{"type"};
             my $sn=$comparisons->{$comparison}->{"sn"};
             my $pv=$comparisons->{$comparison}->{"pvalue"};
             my $fc=$comparisons->{$comparison}->{"foldchange"};
                $pv=1, unless($pv);
             print "$comparison: $sn samples\n";
             print "$comparison: Pvalue cutoff $pv\n";
             print "$comparison: Foldchange cutoff $fc\n";
             my $input="$junction_reads\_$comparison\_annotation";
             if($mode eq 'all')
             {
                 $pv=1;
                 $fc=1;
                 $input="$junction_reads\_$comparison\_all_annotation";
             }

              open (INPUT, "$input.txt") or die "error($junction_reads\_$comparison\_annotation.txt):$!";
              if($mode eq 'de')
              {
              open (HEATMAP, ">heatmap.$comparison.txt") or die "error(heatmap_$comparison.txt):$!";
              open (GOUP, ">go.up_$comparison.txt") or die "error(go_up_$comparison.txt):$!";
              open (GODN, ">go.down_$comparison.txt") or die "error(go_down_$comparison.txt):$!";
              open (PWUP, ">pathway.up_$comparison.txt") or die "error(pathway_up_$comparison.txt):$!";
              open (PWDN, ">pathway.down_$comparison.txt") or die "error(pathway_down_$comparison.txt):$!";
              }
              my $line;
              $line=<INPUT>;
              chomp $line;
               $line=~ s/[\r\n]//g;
              my @head = split(/\t/,$line);
              my ($regu_index,$gene_index);
              for(my $i=0;$i<$#head;$i++)
              {
				  $regu_index = $i,if($head[$i] eq "regulation");
                  $gene_index = $i,if($head[$i] eq "GeneName");
	      }
              if($mode eq 'de')
              {
                   my @group=@head[($regu_index+$sn+1)..($regu_index+2*$sn)];
                   for(my $i=0;$i<=$#group;$i++)
                   {
                      $group[$i]='['.$group[$i].", ".$comparisons->{$comparison}->{"group"}->{$group[$i]}.']';
                   }

                   $line = join("\t",$head[0],@group);
                   print HEATMAP "$line\n";
              }

              my %up;
              my %down;
              while($line=<INPUT>)
              {
                 chomp $line;
                  $line=~ s/[\r\n]//g;
                 my @line=split(/\t/,$line);
                    if($line[$regu_index] eq "up")
                    {
						$up{$line}=$line[1];
                                                if($line[$gene_index])
                                                {
                                                  if($mode eq 'de')
                                                  {
                                                  print GOUP "$line[$gene_index]\n";
                                                  print PWUP "$line[$gene_index]\torange\n";
                                                  }
                                                }
					}
					else
					{
						$down{$line}=$line[1];
                                                if($line[$gene_index])
                                                {
                                                  if($mode eq 'de')
                                                  {
                                                  print GODN "$line[$gene_index]\n";
                                                  print PWDN "$line[$gene_index]\tyellow\n";
                                                  }
                                                }
					}
                    if($mode eq 'de')
                    {
                         $line = join("\t",@line[0,($regu_index+$sn+1)..($regu_index+2*$sn)]);
                         print HEATMAP "$line\n";
                    }
               }
               close INPUT;
               if($mode eq 'de')
               {
               close GOUP;
               close GODN;
               close PWUP;
               close PWDN;
               close HEATMAP;
               }

   my $default=$workbook->add_format();
      $default->set_font('Times New Roman');
      $default->set_size(11);
      #$default->set_border(1);

   my $bold_red=$workbook->add_format();
      $bold_red->set_font('Times New Roman');
      $bold_red->set_bold();
      $bold_red->set_color('red');
      $bold_red->set_size(11);

   my $bold=$workbook->add_format();
      $bold->set_font('Times New Roman');
      $bold->set_bold();
      $bold->set_size(11);
      #$bold->set_border(1);

   my $title1=$workbook->add_format();
      $title1->set_font('Times New Roman');
      $title1->set_bold();
      $title1->set_size(11);
      $title1->set_bg_color( '#3366ff' );
      #$title1->set_border(1);
      $title1->set_align('center');

   my $title2=$workbook->add_format();
      $title2->set_font('Times New Roman');
      $title2->set_bold();
      $title2->set_size(11);
      $title2->set_bg_color( '#ff9900' );
      # $title2->set_border(1);
      $title2->set_align('center');

   my $title3=$workbook->add_format();
      $title3->set_font('Times New Roman');
      $title3->set_bold();
      $title3->set_size(11);
      $title3->set_bg_color( '#008080' );
      #$title3->set_border(1);
      $title3->set_align('center');

   my $title4=$workbook->add_format();
      $title4->set_font('Times New Roman');
      $title4->set_bold();
      $title4->set_size(11);
      $title4->set_bg_color( '#00ccff' );
      #$title1->set_border(1);
      $title4->set_align('center');

   my $title5=$workbook->add_format();
      $title5->set_font('Times New Roman');
      $title5->set_bold();
      $title5->set_size(11);
      $title5->set_bg_color( '#ff0000' );
      #$title1->set_border(1);
      $title5->set_align('center');

   my $title6=$workbook->add_format();
      $title6->set_font('Times New Roman');
      $title6->set_bold();
      $title6->set_size(11);
      $title6->set_bg_color( '#008000' );
      #$title1->set_border(1);
      $title6->set_align('center');

   my $merge_style=$workbook->add_format();
      $merge_style->set_font('Times New Roman');
      $merge_style->set_bg_color('#ffff99');
      $merge_style->set_text_wrap();
      $merge_style->set_align('top');
      my @updown = qw(up down);
      my $column_index = &get_column_index();
        foreach my $updown(@updown)
        {
                my $sheetname ="$updown\_$comparison";
                   $sheetname =substr($sheetname,0,31), if(length($sheetname)>31);
                my $worksheet = $workbook->add_worksheet($sheetname);
                   $worksheet->set_column( 0, 0, 25 );
                my $aa="Differentially expressed circRNAs for: ";
                my $a1="Fold Change cut-off: ";
                my $a2="P-value cut-off: ";                

        	my $bb="Column A: CircRNAID, the ID of the identified circRNA by DCC.";
                my $b1="Column B ~ ".$column_index->{$regu_index+1}.": edgeR results for differentially expressed circRNAs.";
        	my $c="Column ".$column_index->{$regu_index+2}." ~ ".$column_index->{$regu_index+1+$sn}.": junction reads, the junction read number of each sample.";
        	my $d="Column ".$column_index->{$regu_index+$sn+2}." ~ ".$column_index->{$regu_index+2*$sn+1}.": logCPM by edgeR.";
        	my $e="Column ".$column_index->{$regu_index+$sn*2+1}." ~ ".$column_index->{$regu_index+$sn*2+5}.": the coordinates of circRNA.";
        	my $f="Column ".$column_index->{$regu_index+$sn*2+6}.": circBaseID, the identifier of circBase (http://www.circbase.org).";
        	my $g="Column ".$column_index->{$regu_index+$sn*2+7}.": source, the source of the circRNA, including circBase, Guojunjie2014,...";
        	my $h="Column ".$column_index->{$regu_index+$sn*2+8}.": best_transcript, the best transcript of the circRNA.";
        	my $i="Column ".$column_index->{$regu_index+$sn*2+9}.": GeneName, the name of the circRNA-associated gene.";
        	my $j="Column ".$column_index->{$regu_index+$sn*2+10}.": Catalog, the catalog of the circRNA, including exonic, intronic, ...";
        	my $k="Column ".$column_index->{$regu_index+$sn*2+11}.": predicted_sequence_length, the length of predicted circRNA sequence.";
                my $l="";
                my $wide=$regu_index+$sn*2+11;
        	if( lc($species) eq 'human' )
                {
        	     $l="Column ".$column_index->{$regu_index+$sn*2+12}.": circRNA-associated diseases indicated by (http://gyanxet-beta.com/circdb/).";
                     $wide=$regu_index+$sn*2+12;
                }
                my $head=16;
                $worksheet->merge_range( "A1:$column_index->{$wide}$head", 'Vertical and horizontal', $default);
                $worksheet->write_rich_string( 'A1',$bold, $aa,$bold_red,$sheetname,$bold,"\n$a1",$bold_red,$fc,$bold,"\n$a2",$bold_red,$pv,$default,"\n\n$bb\n$b1\n$c\n$d\n$e\n$f\n$g\n$h\n$i\n$j\n$k\n$l",$merge_style);
                $head++;
                if($updown eq 'up')
                {
                    $worksheet->merge_range($head,1,$head,$wide-1,"$comparison $updown regulated circRNAs",$title5);
                }
                else
                {
                    $worksheet->merge_range($head,1,$head,$wide-1,"$comparison $updown regulated circRNAs",$title6);
                }
                $head++;
                $worksheet->merge_range($head,1,$head,$regu_index,'P-value, Fold change and Regulation',$title4);
                $worksheet->merge_range($head,$regu_index+1,$head,$regu_index+$sn,'junction reads',$title1);
	        $worksheet->merge_range($head,$regu_index+$sn+1,$head,$regu_index+$sn*2,'logCPM by edgeR',$title2);
                $worksheet->merge_range($head,$regu_index+$sn*2+1,$head,$wide-1,'Annotations',$title3);
                $head++;
                my $row=0;                
                   for(my $i=0;$i<=$#head;$i++)
                     {
                            $worksheet->write($head+$row,$i,$head[$i],$bold);
                      }
                     $row++;
                my %updown = %up;
                   %updown = %down, if($updown eq 'down');
                   
            if($updown eq 'down')
             {
                foreach my $line (sort {$down{$a} <=> $down{$b}} keys %down)
                {
                      my @line=split(/\t/,$line);
                     for(my $i=0;$i<=$#line;$i++)
                     {
                         if($row == 0)
                          {
                            $worksheet->write($head+$row,$i,$line[$i],$bold);
                          }
                          else
                          {
                            $worksheet->write($head+$row,$i,$line[$i],$default);
                          }
                      }
                      $row++;
                }
			}
			else
			{
				foreach my $line (sort {$up{$b} <=> $up{$a}} keys %up)
                {
                      my @line=split(/\t/,$line);
                     for(my $i=0;$i<=$#line;$i++)
                     {
                         if($row == 0)
                          {
                            $worksheet->write($head+$row,$i,$line[$i],$bold);
                          }
                          else
                          {
                            $worksheet->write($head+$row,$i,$line[$i],$default);
                          }
                      }
                      $row++;
                }
			}
        }## updown
        }## comparisons
   $workbook->close();
   ########################################################################################
}

sub edgeR_profiling_excel
{
	print "\t\t\t\t\t\t\tprofiling_excel\n";
   my ($profiling,$sn,$species)=@_;
       open (INPUT, "$profiling.txt") or die "error($profiling.txt):$!";
       my $line;
   my $workbook = Excel::Writer::XLSX->new('CircRNA Expression Profiling.xlsx');
   my $worksheet = $workbook->add_worksheet('circRNA Expression Profiling');
      $worksheet->set_column( 0, 0, 25 );

   my $default=$workbook->add_format();
      $default->set_font('Times New Roman');
      $default->set_size(11);
      #$default->set_border(1);

   my $bold=$workbook->add_format();
      $bold->set_font('Times New Roman');
      $bold->set_bold();
      $bold->set_size(11);
      #$bold->set_border(1);

   my $title1=$workbook->add_format();
      $title1->set_font('Times New Roman');
      $title1->set_bold();
      $title1->set_size(11);
      $title1->set_bg_color( '#3366ff' );
      #$title1->set_border(1);
      $title1->set_align('center');

   my $title2=$workbook->add_format();
      $title2->set_font('Times New Roman');
      $title2->set_bold();
      $title2->set_size(11);
      $title2->set_bg_color( '#ff9900' );
      # $title2->set_border(1);
      $title2->set_align('center');

   my $title3=$workbook->add_format();
      $title3->set_font('Times New Roman');
      $title3->set_bold();
      $title3->set_size(11);
      $title3->set_bg_color( '#008080' );
      #$title3->set_border(1);
      $title3->set_align('center');

   my $merge_style=$workbook->add_format();
      $merge_style->set_font('Times New Roman');
      $merge_style->set_bg_color('#ffff99');
      $merge_style->set_text_wrap();
      $merge_style->set_align('top');
      my $column_index = &get_column_index();

      my $a="circRNAs identified by DCC";
	my $b="Column A: CircRNAID, the ID of the identified circRNA by DCC.";
	my $c="Column B ~ ".$column_index->{$sn+1}.": junction reads, the junction read number of each sample.";
	my $d="Column ".$column_index->{$sn+2}." ~ ".$column_index->{2*$sn+1}.": logCPM by edgeR.";
	my $e="Column ".$column_index->{$sn*2+2}." ~ ".$column_index->{$sn*2+5}.": the coordinates of circRNA.";
	my $f="Column ".$column_index->{$sn*2+6}.": circBaseID, the identifier of circBase (http://www.circbase.org).";
	my $g="Column ".$column_index->{$sn*2+7}.": source, the source of the circRNA, including circBase, Guojunjie2014,...";
	my $h="Column ".$column_index->{$sn*2+8}.": best_transcript, the best transcript of the circRNA.";
	my $i="Column ".$column_index->{$sn*2+9}.": GeneName, the name of the circRNA-associated gene.";
	my $j="Column ".$column_index->{$sn*2+10}.": Catalog, the catalog of the circRNA, including exonic, intronic, ...";
	my $k="Column ".$column_index->{$sn*2+11}.": predicted_sequence_length, the length of predicted circRNA sequence.";
        my $l="";
        my $wide=$sn*2+11;
	if( lc($species) eq 'human' )
        {
	     $l="Column ".$column_index->{$sn*2+12}.": circRNA-associated diseases indicated by (http://gyanxet-beta.com/circdb/).";
             $wide=$sn*2+12;
        }
        my $head=13;
        $worksheet->merge_range( "A1:$column_index->{$wide}$head", 'Vertical and horizontal', $default);
        $worksheet->write_rich_string( 'A1',$bold, $a, $default,"\n\n$b\n$c\n$d\n$e\n$f\n$g\n$h\n$i\n$j\n$k\n$l",$merge_style);
   $head++;
        $worksheet->merge_range($head,1,$head,$sn,'junction reads',$title1);
	$worksheet->merge_range($head,$sn+1,$head,$sn*2,'logCPM by edgeR',$title2);
        $worksheet->merge_range($head,$sn*2+1,$head,$wide-1,'Annotations',$title3);
   $head++;
   my $row=0;
   while($line=<INPUT>)
   {
        chomp $line;
         $line=~ s/[\r\n]//g;
        my @line=split(/\t/,$line);
        for(my $i=0;$i<=$#line;$i++)
        {    if($row == 0)
             {
               $worksheet->write($head+$row,$i,$line[$i],$bold);
             }
             else
             {
               $worksheet->write($head+$row,$i,$line[$i],$default);
             }
         }
         $row++;

   }
   $workbook->close();
    close INPUT;
   ########################################################################################
}

sub rename_fq_files
{
        my ($raw_dir,$file_type,$read_type,$read_suffix1,$read_suffix2)=@_; 
        print "rename_fq_files file_type:$file_type,$read_type,$read_suffix1,$read_suffix2\n";
        print "rename_fq_files start:\n";
        my ($usr,$samples,$sampleindex,$sample_group) = &read_config();      
      foreach my $reads(keys %{$samples})
      {
           my ($read1,$read2)=($reads.$read_suffix1.".".$file_type, $reads.$read_suffix2.".".$file_type);
           print "rename: $read1,$read2\n";
           if(-f "$raw_dir/$read1")
           {
                   print "rename $raw_dir/$read1\n";
                   my $newname =$samples->{$reads}.$read_suffix1.".$file_type"; 
                   rename "$raw_dir/$read1","$raw_dir/$newname";
		    }
		    if(-f "$raw_dir/$read1.line_count")
           {
                   print "rename $raw_dir/$read1.line_count\n";
                   my $newname =$samples->{$reads}.$read_suffix1.".$file_type.line_count"; 
                   rename "$raw_dir/$read1.line_count","$raw_dir/$newname";
		    }
		   if(-f "$raw_dir/$read2")
           {
                   print "rename $raw_dir/$read2\n";
                   my $newname =$samples->{$reads}.$read_suffix2.".$file_type"; 
                   rename "$raw_dir/$read2","$raw_dir/$newname";
		    }
		    if(-f "$raw_dir/$read2.line_count")
           {
                   print "rename $raw_dir/$read2.line_count\n";
                   my $newname =$samples->{$reads}.$read_suffix2.".$file_type.line_count"; 
                   rename "$raw_dir/$read2.line_count","$raw_dir/$newname";
		    }
      }      
}



1;

