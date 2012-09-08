#!/usr/bin/perl
use strict;
use warnings;
use File::Path;
use Fcntl;
use File::Find;
use IO::File;
use Cwd 'abs_path';

my $omit_file = 0;

sub escapeNSIS {
  my $a = shift(@_);
  $a =~ s/\$/\$\$/g;
  $a =~ s/"/\$\\"/g;
  $a =~ s/\n/\$\\n/g;
  $a =~ s/\r/\$\\r/g;
  $a =~ s/\t/\$\\t/g;
  return $a;
}
sub getLicenseFile {
  my $license = shift;
  if($license eq "LGPL") {
    return "licenses\\lgpl-2.1.txt";
  } elsif($license eq "GPL") {
    return "licenses\\gpl-2.0.txt";
  } elsif($license eq "OCaml-QPL") {
    return "licenses\\ocaml-qpl.txt";
  } elsif($license eq "Camlp5-BSDL") {
    return "licenses\\camlp5-bsdl.txt";
  } elsif($license eq "CeCILL_B") {
    return "licenses\\Licence_CeCILL-B_V1-en.txt";
  } else {
    print "error: unknown license $license";
    die;
  }
}

my $wd = abs_path(".");

my $file = IO::File->new();
$file->open('installer.nsi', 'w') or die $!;


#my $coq_root = "C:/coq";
#my $coq_version = "8.3pl4";
#my $coq_version = "C:/ocamlmgw";
my $coq_root = $ARGV[0];
my $coq_version = $ARGV[1];
my $ocaml_root = $ARGV[2];
my $ocaml_version = $ARGV[3];
my $coq_root_win = $coq_root;
$coq_root_win =~ s/\//\\/g;
my $ocaml_root_win = $ocaml_root;
$ocaml_root_win =~ s/\//\\/g;

my %contribs = ();
my %licenses = ();
$licenses{"OCaml-QPL"} = ["OCaml"];
$licenses{"Camlp5-BSDL"} = ["OCaml"];

sub proc0 {
  my $abs_path = $File::Find::name;
  if($abs_path ne $coq_root) {
    my $rel_path = substr($File::Find::name, length($coq_root)+1, length($abs_path)-length($coq_root)-1);
    my $rel_path_win = $rel_path;
    $rel_path_win =~ s/\//\\/g;
    if($rel_path =~ m/^lib\/user-contrib\/([^\/]+)/) {
      my $contrib = $1;
      if(not exists $contribs{$contrib}) {
	my $desc = {};
	if($contrib eq "Ssreflect") {
	  $desc = {
	    "License"=>"CeCILL_B",
	    "Title"=>"The Small Scale Reflect(ssreflect) package",
	    "Description"=>"This package provides some extensional tactics and massive amounts of mathematical theorems."
	  };
	} else {
	  my $descfile = IO::File->new();
	  $descfile->open("$wd/contrib-$coq_version/$contrib/description", 'r') or die $!;
	  foreach my $line (<$descfile>) {
	    if($line =~ m/^License: (.*)$/) {
	      $$desc{"License"} = $1
	    } elsif($line =~ m/^Title: (.*)$/) {
	      $$desc{"Title"} = $1
	    } elsif($line =~ m/^Description: (.*)$/) {
	      $$desc{"Description"} = $1
	    }
	  }
	  $descfile->close();
	  if(not exists $$desc{"License"}) {
	    my $licfile = IO::File->new();
	    if($licfile->open("$wd/contrib-$coq_version/$contrib/LICENSE", 'r')) {
	      foreach my $line (<$licfile>) {
		if($line =~ m/GNU Lesser General Public License/i) {
		  $$desc{"License"} = "LGPL";
		}
	      }
	    } else {
	      print "License of $contrib is unknown: File Not Found\n";
	      $$desc{"License"}="FileNotFound";
	    }
	    $licfile->close();
	  }
	  if(not exists $$desc{"License"}) {
	    print "License of $contrib is unknown\n";
	  } elsif($$desc{"License"} eq "GPL") {
	  } elsif($$desc{"License"} eq "LGPL") {
	  } elsif($$desc{"License"} eq "GNU LGPL") {
	    $$desc{"License"}="LGPL";
	  } elsif($$desc{"License"} eq "GNU Lesser General Public License") {
	    $$desc{"License"}="LGPL";
	  } elsif($$desc{"License"} eq "GNU Lesser Public License") {
	    $$desc{"License"}="LGPL";
	  } elsif($$desc{"License"} eq "FileNotFound") {
	    delete $$desc{"License"};
	  } else {
	    print "License of $contrib is unknown: $$desc{'License'}\n";
	    delete $$desc{"License"};
	  }
	}
	if(exists $$desc{"License"}) {
	  if(not exists $licenses{$$desc{"License"}}) {
	    $licenses{$$desc{"License"}} = [];
	  }
	  push($licenses{$$desc{"License"}}, $contrib);
	}
	$contribs{$contrib} = $desc;
      }
    }
  }
}
find(\&proc0, $coq_root);

$file->print("OutFile \"coq-unofficial-${coq_version}-win32.exe\"\n");
$file->print(<<'EOD');
SetCompressor lzma
RequestExecutionLevel highest
!addincludedir .
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_EXECUTIONLEVEL "Highest"
!define MULTIUSER_INSTALLMODE_INSTDIR "Coq-Unofficial"
!include "LogicLib.nsh"
!include "nsDialogs.nsh"
!include "Sections.nsh"
!include "MultiUser.nsh"
!include "MUI2.nsh"
!include "FileAssociation.nsh"

Var FileAssociationCheckbox
Var FileAssociationCheckboxState
Var StartMenuFolder

Name "Coq Unofficial Build"
Icon "logo.ico"

InstallDirRegKey HKCU "Software\Coq-Unofficial" ""

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "licenses\lgpl-2.1.txt"
!insertmacro MUI_PAGE_COMPONENTS
EOD

foreach my $license (sort(keys(%licenses))) {
  if($license eq "LGPL") {
    next;
  }
  $file->printf("!define MUI_PAGE_CUSTOMFUNCTION_PRE CustomPage_license_$license\n");
  $file->printf("!insertmacro MUI_PAGE_LICENSE \"" . escapeNSIS(getLicenseFile($license)) . "\"\n");
  $file->printf("\n");
}
$file->print(<<'EOD');
!insertmacro MULTIUSER_PAGE_INSTALLMODE
!insertmacro MUI_PAGE_DIRECTORY

!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\Coq-Unofficial"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder
Page custom PageAskingFileAssociation PageAskingFileAssociationLeave

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

Function .onInit
  !insertmacro MULTIUSER_INIT
FunctionEnd

Function un.onInit
  !insertmacro MULTIUSER_UNINIT
FunctionEnd

Section "Core Coq Component" Section_core
  SectionIn RO
EOD

sub proc1 {
  my $abs_path = $File::Find::name;
  if($abs_path ne $coq_root) {
    my $rel_path = substr($File::Find::name, length($coq_root)+1, length($abs_path)-length($coq_root)-1);
    my $rel_path_win = $rel_path;
    $rel_path_win =~ s/\//\\/g;
    if($rel_path !~ m/^lib\/user-contrib\/([^\/]+)/) {
      if(-d $abs_path) {
	$file->print("  CreateDirectory \$INSTDIR\\$rel_path_win\n");
      } elsif(not $omit_file) {
	$file->print("  File /oname=\$INSTDIR\\$rel_path_win $coq_root_win\\$rel_path_win\n");
      }
    }
  }
}
find(\&proc1, $coq_root);

$file->print(<<'EOD');
  File /oname=$INSTDIR\LICENSE-Coq.txt "licenses\lgpl-2.1.txt"
  WriteRegStr HKCU "Software\Coq-Unofficial" "" $INSTDIR
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    ;Create shortcuts
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\CoqIDE.lnk" "$INSTDIR\bin\coqide.exe"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Coq Console.lnk" "$INSTDIR\bin\coqtop.exe"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  !insertmacro MUI_STARTMENU_WRITE_END

  ${If} $FileAssociationCheckboxState <> 0
    ${registerExtension} "$INSTDIR\bin\coqide.exe" ".v" "Coq vernacular file"
  ${EndIf}

SectionEnd
LangString DESC_Section_core ${LANG_ENGLISH}  "Core Coq Component"

EOD

$file->print(<<'EOD');

Section /o "OCaml" Section_OCaml
EOD

sub proc2 {
  my $abs_path = $File::Find::name;
  if($abs_path ne $ocaml_root) {
    my $rel_path = substr($File::Find::name, length($ocaml_root)+1, length($abs_path)-length($ocaml_root)-1);
    my $rel_path_win = $rel_path;
    $rel_path_win =~ s/\//\\/g;
    if(-d $abs_path) {
      $file->print("  CreateDirectory \$INSTDIR\\$rel_path_win\n");
    } elsif(not $omit_file) {
      $file->print("  File /oname=\$INSTDIR\\$rel_path_win $ocaml_root_win\\$rel_path_win\n");
    }
  }
}
find(\&proc2, $ocaml_root);
$file->print("  File /oname=\$INSTDIR\\ocaml-$ocaml_version.tar.bz2 ocaml-$ocaml_version.tar.bz2\n");
$file->print("  File /oname=\$INSTDIR\\LICENSE-OCaml.txt \"licenses\\ocaml-qpl.txt\"\n");

$file->print(<<'EOD');
SectionEnd
LangString DESC_Section_OCaml ${LANG_ENGLISH}  "OCaml (for building extensions)"

EOD


sub proc3 {
  my $abs_path = $File::Find::name;
  my $rel_path = substr($File::Find::name, length($coq_root)+1, length($abs_path)-length($coq_root)-1);
  my $rel_path_win = $rel_path;
  $rel_path_win =~ s/\//\\/g;
  if(-d $abs_path) {
    $file->print("  CreateDirectory \$INSTDIR\\$rel_path_win\n");
  } elsif(not $omit_file) {
    $file->print("  File /oname=\$INSTDIR\\$rel_path_win $coq_root_win\\$rel_path_win\n");
  }
}

if(exists $contribs{"Ssreflect"}) {
  my $contrib = "Ssreflect";
  $file->print("Section \"${contrib}\" Section_${contrib}\n");
  find(\&proc3, "$coq_root/lib/user-contrib/$contrib");
  $file->print("  File /oname=\$INSTDIR\\LICENSE-$contrib.txt \"" . escapeNSIS(getLicenseFile($contribs{$contrib}->{'License'})) . "\"\n");
  $file->print("SectionEnd\n");
  $file->print("LangString DESC_Section_${contrib} \${LANG_ENGLISH}  \"" . escapeNSIS("$contribs{$contrib}->{'Title'}\n$contribs{$contrib}->{'Description'} ( License: $contribs{$contrib}->{'License'} )") . "\"\n\n");
}

$file->print("SectionGroup \"contribution packages\" SectionGroup_contribs\n");
foreach my $contrib (sort(keys(%contribs))) {
  if($contrib eq "Ssreflect") {
    next;
  }
  if(not exists $contribs{$contrib}->{"License"}) {
    next;
  }
  if(not exists $contribs{$contrib}->{"Description"}) {
    $contribs{$contrib}->{"Description"} = "";
  }
  if(not exists $contribs{$contrib}->{"Title"}) {
    $contribs{$contrib}->{"Title"} = $contrib;
  }
  $file->print("Section /o \"${contrib}\" Section_${contrib}\n");
  find(\&proc3, "$coq_root/lib/user-contrib/$contrib");
  $file->print("  File /oname=\$INSTDIR\\LICENSE-$contrib.txt \"" . escapeNSIS(getLicenseFile($contribs{$contrib}->{'License'})) . "\"\n");
  $file->print("SectionEnd\n");
  $file->print("LangString DESC_Section_${contrib} \${LANG_ENGLISH}  \"" . escapeNSIS("$contribs{$contrib}->{'Title'}\n$contribs{$contrib}->{'Description'} ( License: $contribs{$contrib}->{'License'} )") . "\"\n\n");
}
$file->print("SectionGroupEnd\n");
$file->print("LangString DESC_SectionGroup_contribs \${LANG_ENGLISH}  \"Coq contribution packages\"\n");

$file->print("!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN\n");
$file->printf("  !insertmacro MUI_DESCRIPTION_TEXT \${Section_core} \$(DESC_Section_core)\n");
$file->printf("  !insertmacro MUI_DESCRIPTION_TEXT \${Section_OCaml} \$(DESC_Section_OCaml)\n");
$file->printf("  !insertmacro MUI_DESCRIPTION_TEXT \${SectionGroup_contribs} \$(DESC_SectionGroup_contribs)\n");
foreach my $contrib (sort(keys(%contribs))) {
  if(not exists $contribs{$contrib}->{"License"}) {
    next;
  }
  $file->printf("  !insertmacro MUI_DESCRIPTION_TEXT \${Section_$contrib}      \$(DESC_Section_$contrib)\n");
}
$file->print("!insertmacro MUI_FUNCTION_DESCRIPTION_END\n");

$file->print(<<'EOD');
Section "Uninstall"
  # Remove files
EOD

sub proc4 {
  my $abs_path = $File::Find::name;
  if($abs_path ne $coq_root) {
    my $rel_path = substr($File::Find::name, length($coq_root)+1, length($abs_path)-length($coq_root)-1);
    my $rel_path_win = $rel_path;
    $rel_path_win =~ s/\//\\/g;
    if(-d $abs_path) {
      $file->print("  RmDir \$INSTDIR\\$rel_path_win\n");
    } else {
      $file->print("  Delete \$INSTDIR\\$rel_path_win\n");
    }
  }
}
finddepth(\&proc4, $coq_root);

sub proc5 {
  my $abs_path = $File::Find::name;
  if($abs_path ne $ocaml_root) {
    my $rel_path = substr($File::Find::name, length($ocaml_root)+1, length($abs_path)-length($ocaml_root)-1);
    my $rel_path_win = $rel_path;
    $rel_path_win =~ s/\//\\/g;
    if(-d $abs_path) {
      $file->print("  RmDir \$INSTDIR\\$rel_path_win\n");
    } elsif(not $omit_file) {
      $file->print("  Delete \$INSTDIR\\$rel_path_win\n");
    }
  }
}
finddepth(\&proc5, $ocaml_root);
$file->print("  Delete \$INSTDIR\\LICENSE-Coq.txt\n");
$file->print("  Delete \$INSTDIR\\LICENSE-OCaml.txt\n");
foreach my $contrib (sort(keys(%contribs))) {
  $file->print("  Delete \$INSTDIR\\LICENSE-$contrib.txt\n");
}

$file->print(<<'EOD');
  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
  Delete "$SMPROGRAMS\$StartMenuFolder\Coq Console.lnk"
  Delete "$SMPROGRAMS\$StartMenuFolder\CoqIDE.lnk"
  Delete "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk"
  RMDir "$SMPROGRAMS\$StartMenuFolder"

  ${unregisterExtension} ".v" "Coq vernacular file"

  # Always delete uninstaller as the last action
  Delete $INSTDIR\Uninstall.exe
  
  # Try to remove the install directory - this will only happen if it is empty
  RmDir $INSTDIR

  # Remove uninstaller information from the registry
  DeleteRegKey /ifempty HKCU "Software\Coq-Unofficial"
SectionEnd

Function PageAskingFileAssociation
  nsDialogs::Create 1018
  !insertmacro MUI_HEADER_TEXT "File Association" "Check if you want to associate *.v files to CoqIDE."
  ${NSD_CreateCheckbox} 80u 50u 100% 10u "Associate *.v files to CoqIDE"
  Pop $FileAssociationCheckbox
  nsDialogs::Show
FunctionEnd

Function PageAskingFileAssociationLeave
  ${NSD_GetState} $FileAssociationCheckbox $FileAssociationCheckboxState
FunctionEnd

EOD

foreach my $license (sort(keys(%licenses))) {
  if($license eq "LGPL") {
    next;
  }
  $file->printf("Function CustomPage_license_$license\n");
  my $isfirst = 1;
  foreach my $contrib (@{$licenses{$license}}) {
    if($isfirst) {
      $file->printf("  \${IfNot} \${SectionIsSelected} \${Section_$contrib}\n");
    } else {
      $file->printf("  \${AndIfNot} \${SectionIsSelected} \${Section_$contrib}\n");
    }
    $isfirst = 0;
  }
  $file->printf("  Abort\n");
  $file->printf("  \${EndIf}\n");
  $file->printf("FunctionEnd\n");
  $file->printf("\n");
}

$file->close();

