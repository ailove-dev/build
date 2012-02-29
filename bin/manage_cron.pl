#!/usr/bin/perl
use strict;
use XML::Simple;
use Data::Dumper;

#print Dumper (XML::Simple->new()->XMLin());

my $i=0;
my $iter=0;
my $simple = XML::Simple->new();
my $simple_time = XML::Simple->new();
my $data = {};
my $data_time;
my $projects;
my $ioff;
my $cron_enable;
my $always_cron_enable;
my $ident_project;
my $data_time;

for($i=0;$i<=$iter;$i++) {
  $ioff=100*$i;
  `/usr/bin/curl -s -H "Content-Type: application/xml" -X GET -H "X-Redmine-API-Key: b94cd05053447864c61039ea56504ac3f2db678f" "http://factory.ailove.ru/projects.xml?limit=100&offset=$ioff" >/tmp/prrr.xml`;
   $data = {};
   eval {$data = $simple->XMLin('/tmp/prrr.xml');};
##   print $data->{'total_count'};
   $iter = int($data->{'total_count'} / 100);
##   print " $ioff, $iter \n";
   $projects = $data->{'project'};
   while ( my ($key, $value) = each(%$projects) ) {
#          		 print "$key => $value\n";
#	    print $projects->{$key}->{'identifier'};
           $ident_project=$projects->{$key}{'identifier'};
           $cron_enable=$projects->{$key}{'custom_fields'}{'custom_field'}{'Enable cron task'}{'value'};
           if ($cron_enable!=0) {$cron_enable=1;};
           $always_cron_enable=$projects->{$key}{'custom_fields'}{'custom_field'}{'Always enabled cron task'}{'value'};
           if ($always_cron_enable!=1) {$always_cron_enable=0;};
           $cron_enable+=$always_cron_enable;
#	   print " - $cron_enable\n";
	   my $fn_l="/etc/cron.d/".$ident_project;
	   my $fn_c="/srv/www/".$ident_project."/conf/crontab";
	   if ($cron_enable > 0) {
	     if (not (-l $fn_l)) {
	     ## create symlink to cron
#	     print "$fn_c\n";
	       if (-f $fn_c) {
	         `/bin/ln -s $fn_c $fn_l`;
	       };
	     };
	   }else{
##	     print "$fn_c $fn_l\n";
	     if (-l $fn_l) {
	        `/bin/rm -f $fn_l`;
	     };
	   };
   }

}
