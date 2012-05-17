#!/usr/bin/perl
use strict;
use utf8;
use XML::Simple;
use Data::Dumper;
use Encode;
#use Encode 'from_to';
#use Encode 'utf8_off';
use Time::Local;

my $i=0;
my $iter=0;
my $simple = XML::Simple->new();
my $simple_time = XML::Simple->new();
my $simple_pro = XML::Simple->new();
my $simple_memb = XML::Simple->new();
my $data;
my $data_time;
my $data_pro;
my $data_memb;
my $projects;
my $ioff;
my $cron_enable;
my $always_cron_enable;
my $ident_project;
my $data_time;
my $cc_email="";
my $project_name;
my $project_id;
my $project_id_num;
my $report_str;
my $year;
my $mon;
my $mday;
my $members;

for($i=0;$i<=$iter;$i++) {
  $ioff=100*$i;
  `curl -s -H "Content-Type: application/xml" -X GET -H "X-Redmine-API-Key: b94cd05053447864c61039ea56504ac3f2db678f" "http://factory.ailove.ru/projects.xml?limit=100&offset=$ioff" >/tmp/prrr.xml`;
   my $data = $simple->XMLin('/tmp/prrr.xml');
   $iter = int($data->{'total_count'} / 100);
   $projects = $data->{'project'};
   while ( my ($key, $value) = each(%$projects) ) {
	    $cc_email="bond\@techno-r.ru ";
	    $report_str="";
	    $project_name=$key;
	    $project_id=$projects->{$key}->{'identifier'};
	    $project_id_num=$projects->{$key}->{'id'};
##	    print "#### $projects->{$key}->{'identifier'}";
##	    print " - $project_id_num - ";
           $ident_project=$projects->{$key}{'identifier'};
           $cron_enable=$projects->{$key}{'custom_fields'}{'custom_field'}{'Enable cron task'}{'value'};
	   if ( $cron_enable != 0 ){$cron_enable=1;};
           $always_cron_enable=$projects->{$key}{'custom_fields'}{'custom_field'}{'Always enabled cron task'}{'value'};
           if ($always_cron_enable!=1) {$always_cron_enable=0;};
##	   print "ce: $cron_enable - ";
	  `curl -s -H "Content-Type: application/xml" -X GET -H "X-Redmine-API-Key: b94cd05053447864c61039ea56504ac3f2db678f" "http://factory.ailove.ru/projects/$ident_project/time_entries.xml?limit=1" >/tmp/prrr1.xml`;
	   $data_time = {};
	   eval { $data_time = $simple_time->XMLin('/tmp/prrr1.xml');};
	   my $not_activity=1;
#	   print Dumper($data_time);
	   if (exists($data_time->{'time_entry'})) { 
##	     print "$data_time->{'time_entry'}{'spent_on'} ";
	     my $issue_data=$data_time->{'time_entry'}{'spent_on'};
	     ($year, $mon, $mday) = split('-',$issue_data);
	     $issue_data = timelocal(0,0,0, $mday, $mon-1, $year-1900);
	     $issue_data = time()-$issue_data;
	     $issue_data = int ($issue_data/86400);
	     if ($issue_data < 32) {$not_activity=0;};
##	     print "($issue_data) - ";
	   };
##	   print "activ: $not_activity";
##	   print "\n";
### disable cron
	   if (($not_activity==1) and ($cron_enable==1)) {
	     `curl -s -H "Content-Type: application/xml" -X GET -H "X-Redmine-API-Key: b94cd05053447864c61039ea56504ac3f2db678f" "http://factory.ailove.ru/projects/$ident_project.xml" >/tmp/prrr2.xml`;
	     $data_pro = {};
	     eval { $data_pro = $simple_pro->XMLin('/tmp/prrr2.xml');};
	     $data_pro->{'custom_fields'}{'custom_field'}{'Enable cron task'}{'value'}=0;
	     `echo '<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<project>
<custom_fields type=\"array\">
<custom_field name="Always enabled cron task" id="4">
<value>$always_cron_enable</value>
</custom_field>
<custom_field name=\"Enable cron task\" id=\"5\">
<value>0</value>
</custom_field>
</custom_fields>
</project> ' > /tmp/prrr2o.xml`;
	     `curl -s -H "Content-Type: application/xml" -X PUT --data "@/tmp/prrr2o.xml" -H "X-Redmine-API-Key: b94cd05053447864c61039ea56504ac3f2db678f" "http://factory.ailove.ru/projects/$ident_project.xml" >/tmp/prrr.$ident_project.xml`;
	     $report_str="Cron task for project $project_name ($project_id) disabled.\nYou may enable it on https://factory.ailove.ru/projects/$project_id/settings";
	   };
### enable cron
	   if (($not_activity==0) and ($cron_enable==0)) {
	     `curl -s -H "Content-Type: application/xml" -X GET -H "X-Redmine-API-Key: b94cd05053447864c61039ea56504ac3f2db678f" "http://factory.ailove.ru/projects/$ident_project.xml" >/tmp/prrr2.xml`;
	     $data_pro = {};
	     eval { $data_pro = $simple_pro->XMLin('/tmp/prrr2.xml');};
	     $data_pro->{'custom_fields'}{'custom_field'}{'Enable cron task'}{'value'}=0;
	     `echo '<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<project>
<custom_fields type=\"array\">
<custom_field name="Always enabled cron task" id="4">
<value>$always_cron_enable</value>
</custom_field>
<custom_field name=\"Enable cron task\" id=\"5\">
<value>1</value>
</custom_field>
</custom_fields>
</project> ' > /tmp/prrr2o.xml`;
#	     `curl -s -H "Content-Type: application/xml" -X PUT --data "@/tmp/prrr2o.xml" -H "X-Redmine-API-Key: b94cd05053447864c61039ea56504ac3f2db678f" "http://factory.ailove.ru/projects/$ident_project.xml" >/tmp/prrr.$ident_project.xml`;
#	     $report_str="Cron task for project $project_name ($project_id) enabled.\nCheck settings on https://factory.ailove.ru/projects/$project_id/settings";
	   };
#### get email director and manager
	   if ($report_str ne "" ) {    
	     `curl -s -H "Content-Type: application/xml" -X GET -H "X-Redmine-API-Key: b94cd05053447864c61039ea56504ac3f2db678f" "http://factory.ailove.ru/projects/$ident_project/memberships.xml?limit=100" >/tmp/prrr3.xml`;
	     $data_pro = {};
	     eval { $data_pro = $simple_pro->XMLin('/tmp/prrr3.xml',KeyAttr => 'id');};
	     if ($data_pro->{'total_count'}==1) {
###	        print Dumper ($data_pro);
	        $members = {$data_pro->{'membership'}};
####	        $cc_email.=$data_pro->
	     } else {
	     $members = $data_pro->{'membership'};
#	     print Dumper ($members);
	     while ( my ($key_m, $value_m) = each(%$members) ) {
##// id=7 - director, id=3 - manager
		if ((exists($value_m->{'roles'}{'role'}{'7'})) or 
		    (exists($value_m->{'roles'}{'role'}{'3'})) or
		    ((exists($value_m->{'roles'}{'role'}{'id'})) and (($value_m->{'roles'}{'role'}{'id'}==7) or (($value_m->{'roles'}{'role'}{'id'}==3))))
		    ) { 
###		    print "$value_m->{'user'}{'name'} $value_m->{'user'}{'id'}";
		    my $id_member=$value_m->{'user'}{'id'};
		    `curl -s -H "Content-Type: application/xml" -X GET -H "X-Redmine-API-Key: b94cd05053447864c61039ea56504ac3f2db678f" "https://factory.ailove.ru/users/$id_member.xml" >/tmp/prrr4.xml`;
		    $data_memb ={};
		    eval { $data_memb = $simple_memb->XMLin('/tmp/prrr4.xml');};
#		    my $email_memb=$data_memb->{'mail'};
#		    print "email - $email_memb \n";
		    $cc_email.=",".$data_memb->{'mail'}." ";
		};
	     };
	     };
##	     print "$cc_email \n";
	    $report_str = Encode::encode("koi8-r",$report_str);
	    $project_name = Encode::encode("koi8-r",$project_name);
	    $cc_email = Encode::encode("koi8-r",$cc_email);
#	     print "echo '$report_str' | mail -s 'Cron task for $project_name' -c '$cc_email' a.pachay\@ailove.ru\n";
	     `echo "$report_str" | mail -s "Cron task for $project_name" -c '$cc_email' a.pachay\@ailove.ru`;
####
	   };
   }

}
