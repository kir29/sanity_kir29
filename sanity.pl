#!/usr/bin/perl -w

use File::Basename;
use Getopt::Std;

# check for unicodedecoder
my $unidec = 0;
eval { require Text::Unidecode; };
unless ($@) {
  $unidec = 1;
  Text::Unidecode ->import();
}else{
}

# check commandline params
my %OPTS;
getopts('lea',\%OPTS);

# Function prototypes:
sub readFiles($);
sub renameFile($$);
sub help();

##############################################################################
# rename a given File
sub renameFile($$){

  (my $path,$file) = @_;
  my $newfile = $file;

  #remove chars below 32
  $newfile =~ s/[\x00-\x1f]/_/g;

  #urldecode:
  $newfile =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/chr(hex($1))/ge;

  #fix broken unicode chars for german umlauts
  $newfile =~ s/\303\204/Ae/g;
  $newfile =~ s/\303\226/Oe/g;
  $newfile =~ s/\303\234/Ue/g;
  $newfile =~ s/\303\244/ae/g;
  $newfile =~ s/\303\266/oe/g;
  $newfile =~ s/\303\274/ue/g;
  $newfile =~ s/\303\237/ss/g;

  #convert to latin1
  if($unidec){
    $newfile = unidecode($newfile);
  }

  #add more translations here:
  
  $newfile =~ s/\\//g;     #remove backspaces
  $newfile =~ s/\*/x/g;    #windows doesn't like this at all :-)
  $newfile =~ s/&/_and_/g; #ampersand to english
  $newfile =~ s/@/_at_/g;
  $newfile =~ s/['"`]//g;  #remove these completely

  #lowercase some known extensions  
  $newfile =~ s/bat$/bat/gi;
  $newfile =~ s/exe$/exe/gi;
  $newfile =~ s/ogg$/ogg/gi;
  $newfile =~ s/mp3$/mp3/gi;
  $newfile =~ s/rar$/rar/gi;
  $newfile =~ s/pdf$/pdf/gi;
  $newfile =~ s/pdb$/pdb/gi;
  
  #German Umlauts (Linux charset)
  $newfile =~ s/ü/ue/g;
  $newfile =~ s/Ü/Ue/g;
  $newfile =~ s/ö/oe/g;
  $newfile =~ s/Ö/Oe/g;
  $newfile =~ s/ä/ae/g;
  $newfile =~ s/Ä/Ae/g;
  $newfile =~ s/ß/ss/g;

  #German Umlauts (Windows charset)
  $newfile =~ s/\x8e/Ae/g;
  $newfile =~ s/\x99/Oe/g;
  $newfile =~ s/\x9A/Ue/g;
  $newfile =~ s/\x84/ae/g;
  $newfile =~ s/\x94/oe/g;
  $newfile =~ s/\x81/ue/g;
  $newfile =~ s/\xe1/ss/g;
  $newfile =~ s/\253/.5/g;

  # OSX mit HFS+
  #
  # https://tex.stackexchange.com/questions/94418/os-x-umlauts-in-utf8-nfd-yield-package-inputenc-error-unicode-char-u8%CC%88-not/94498
  #
  # Excursus: A Bit of Extra Background on HFS+
  #
  # I first stumbled over this issue when trying to put the output of a ls command into my LaTeX document:
  # The source of many, many problems in OS X is that the HFS+ file system uses (for some totally weird reasons) NFD.
  # Even worse: HFS+ transparently transforms all NFC characters it gets as input into NFD internally.
  # Practically, this means that the filenames you get out are different than those you have put in:
  # If you create a file ü (the keyboard delivers NFC) and then list the directory (the file system delivers NFD) ,
  # the name looks same, but in fact is different.
  # A short illustration test (executed in an empty dir):
  #
  # $ echo ü; echo ü | xxd; touch ü; ls; ls | xxd
  # ü
  # 0000000: c3bc 0a                                  ...
  # ü
  # 0000000: 75cc 880a                                u...
  # This is the reason so many tools (unison, svn, git, ...) or bash's tab completion choke on OS X on filenames containing umlauts
  # and that you cannot use the output of ls directly in your LaTeX document.
  #
  # for i in Ä ä Ö ö Ü ü ß; do echo "echo $i"; echo $i | xxd; touch $i; echo -n "ls "; ls; ls | xxd; rm $i; done
  # echo Ä
  # 00000000: c384 0a                                  ...
  # ls Ä
  # 00000000: 41cc 880a                                A...
  # echo ä
  # 00000000: c3a4 0a                                  ...
  # ls ä
  # 00000000: 61cc 880a                                a...
  # echo Ö
  # 00000000: c396 0a                                  ...
  # ls Ö
  # 00000000: 4fcc 880a                                O...
  # echo ö
  # 00000000: c3b6 0a                                  ...
  # ls ö
  # 00000000: 6fcc 880a                                o...
  # echo Ü
  # 00000000: c39c 0a                                  ...
  # ls Ü
  # 00000000: 55cc 880a                                U...
  # echo ü
  # 00000000: c3bc 0a                                  ...
  # ls ü
  # 00000000: 75cc 880a                                u...
  # echo ß
  # 00000000: c39f 0a                                  ...
  # ls ß
  # 00000000: c39f 0a                                  ...

  # ls ä.txt		mÄ.txt		mÖ.txt		mÜ.txt		ö.txt		ü.txt		ß.txt
  # 00000000: 61cc 882e 7478 740a 6d41 cc88 2e74 7874  a...txt.mA...txt
  # 00000010: 0a6d 4fcc 882e 7478 740a 6d55 cc88 2e74  .mO...txt.mU...t
  # 00000020: 7874 0a6f cc88 2e74 7874 0a75 cc88 2e74  xt.o...txt.u...t
  # 00000030: 7874 0ac3 9f2e 7478 740a                 xt....txt.

  # ls Ä
  # 00000000: 41cc 880a                                A...
  #$newfile =~ s/\x41CC88/Ae/g;
  $newfile =~ s/\x41\xcc\x88/Ae/g;
  # ls Ö
  # 00000000: 4fcc 880a                                O...
  $newfile =~ s/\x4F\xcc\x88/Oe/g;
  # ls Ü
  # 00000000: 55cc 880a                                U...
  $newfile =~ s/\x55\xcc\x88/Ue/g;
  # ls ä
  # 00000000: 61cc 880a                                a...
  #$newfile =~ s/\x61CC88/ae/g;
  $newfile =~ s/\x61\xcc\x88/ae/g;
  # ls ö
  # 00000000: 6fcc 880a                                o...
  #$newfile =~ s/\x6FCC88/oe/g;
  $newfile =~ s/\x6F\xcc\x88/oe/g;
  # ls ü
  # 00000000: 75cc 880a                                u...
  $newfile =~ s/\x75\xcc\x88/ue/g;

  #Accents
  $newfile =~ s/é/e/g;
  $newfile =~ s/É/E/g;
  $newfile =~ s/è/e/g;
  $newfile =~ s/à/a/g;
  $newfile =~ s/â/a/g;
  $newfile =~ s/ô/o/g;
  $newfile =~ s/ñ/n/g;

  $newfile =~ s/\202/_/g;
  $newfile =~ s/\212/_/g;

  $newfile =~ s/_\././g;
  $newfile =~ s/\.\././g;
  $newfile =~ s/\357/'/g;

  #Remove all chars we don't want
  if($OPTS{'e'}){
    $newfile =~ s/[^A-Za-z_0-9\.\-]/_/g;
  }else{
    $newfile =~ s/[^A-Za-z_0-9\(\)\[\]\.\-]/_/g;
  }

  #some cleanup
  $newfile =~ s/_-_/-/g;   #Dashes should not be surounded by underscores
  $newfile =~ s/_-/-/g;
  $newfile =~ s/-_/-/g;
  $newfile =~ s/__+/_/g;    #Reduce multiple spaces to one

  #lowercase if wanted
  $newfile = lc($newfile) if($OPTS{'l'});

  if ("$path/$file" ne "$path/$newfile"){
    print STDERR "Renaming '$file' to '$newfile'";
    if (-e "$path/$newfile"){
            print STDERR "\tSKIPPED new file exists\n";
    }else{
       if (rename("$path/$file","$path/$newfile")){
        print STDERR "\tOKAY\n";
      }else{
        print STDERR "\tFAILED\n";
      }
          }
  }
}

##############################################################################
# Read a given directory and its subdirectories
sub readFiles($) {
  (my $path)=@_;
  
  opendir(ROOT, $path);
  my @files = readdir(ROOT);
  closedir(ROOT);

  foreach (@files) {
    next if /^(\.|\.\.)$/;             #skip upper dirs
    next if((/^\./) && (!$OPTS{'a'})); #skip hidden files
    my $file =$_;
    my $fullFilename    = "$path/$file";
    
    
    if (-d $fullFilename) {
      readFiles($fullFilename); #Recursion
    }
    
    renameFile($path,$file); #Rename

  }
}

##############################################################################
# prints a short Help text
sub help() {
print <<STOP

      Syntax: sanity.pl [options] <file(s)>

      This tool renames files back to sane names. It does so by replacing
      spaces, german umlauts and some special chars by underscores.

      If a renamed version of a file already exists the renaming will be
      skipped.

      Options:

        -l convert to lowercase
        -e extended cleaning (removes brackets as well)
        -a convert all files - don't exclude hidden files and dirs

      The argument can be files and directories. WARNING: Directories will
      be recurseively changed.
      _____________________________________________________________________
      sanity.pl - Sanitize Filenames
      Copyright (C) 2003-2005 Andreas Gohr <andi\@splitbrain.org>

      This program is free software; you can redistribute it and/or
      modify it under the terms of the GNU General Public License as
      published by the Free Software Foundation; either version 2 of
      the License, or (at your option) any later version.
      
      See COPYING for details
STOP
}

##############################################################################
# Main

if (@ARGV < 1){
  &help();
  exit -1;
}

foreach my $arg (@ARGV){
  if(-d $arg){
    &readFiles($arg);
  }else{
    &renameFile(dirname($arg),basename($arg));  
  }
}
