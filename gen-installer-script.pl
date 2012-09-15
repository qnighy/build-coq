#!/usr/bin/perl
use strict;
use warnings;
use File::Path;
use Fcntl;
use File::Find;
use IO::File;
use Cwd 'abs_path';

my $coq_root = $ARGV[0];
my $coq_version = $ARGV[1];
my $ocaml_root = $ARGV[2];
my $ocaml_version = $ARGV[3];
# my $coq_root = "C:/coq-8.4";
# my $coq_version = "8.4";
# my $ocaml_root = "C:/ocamlmgw";
# my $ocaml_version = "4.00.0";
my $wd = abs_path(".");

## Initialize Licenses ##

my $licenses = {};

$licenses->{"CeCILL"  } = InstLicense->new("CeCILL",   "licenses/CeCILL.txt"  );
$licenses->{"CeCILL_B"} = InstLicense->new("CeCILL_B", "licenses/CeCILL_B.txt");
$licenses->{"GPL_2.0" } = InstLicense->new("GPL_2.0",  "licenses/GPL_2.0.txt" );
$licenses->{"GPL_3.0" } = InstLicense->new("GPL_3.0",  "licenses/GPL_3.0.txt" );
$licenses->{"LGPL_2.0"} = InstLicense->new("LGPL_2.0", "licenses/LGPL_2.0.txt");
$licenses->{"LGPL_2.1"} = InstLicense->new("LGPL_2.1", "licenses/LGPL_2.1.txt");
$licenses->{"LGPL_3.0"} = InstLicense->new("LGPL_3.0", "licenses/LGPL_3.0.txt");
$licenses->{"PD"      } = InstLicense->new("PD",       "licenses/PD.txt"      );

## Initialize Groups ##
#
my $groups = {};
my $group_list = [];

push(@$group_list, InstSectionGroup->new("Core", "Coq Core Component", "Coq Core Component", "Single"));
push(@$group_list, InstSectionGroup->new("Ssreflect", "Ssreflect", "Ssreflect", "Single"));
push(@$group_list, InstSectionGroup->new("UserContrib", "User-contribution packages", "User-contribution packages", "Multiple"));

foreach my $group (@$group_list) {
  $groups->{$group->name} = $group;
}

## List Sections ##

my $sections = {};

my $dependencies_file = IO::File->new("contrib-$coq_version/dependencies.txt", 'r') or die $!;
foreach my $dep ($dependencies_file->getlines()) {
  chomp $dep;
  my ($dep_name, $dep_license, $dep_dependencies) = split(/\s+/, $dep);
  my @dep_dependencies_array = grep {$_ ne "None"} split(/,/, $dep_dependencies);
  my @dep_dependencies_arrayS = map {$sections->{$_}} @dep_dependencies_array;
  if(exists $licenses->{$dep_license}) {
    my $description = readDescription($dep_name);
    if(not exists $description->{"Title"}) {
      $description->{"Title"} = $dep_name;
    }
    if(not exists $description->{"Description"}) {
      $description->{"Description"} = "";
    }

    $sections->{$dep_name} = InstSection->new(
      $dep_name,
      $licenses->{$dep_license},
      \@dep_dependencies_arrayS,
      $description->{"Title"},
      $description->{"Description"},
      "Optional",
      $groups->{"UserContrib"}
    );
    # print "Name: $dep_name, License: $dep_license, Dependencies: $dep_dependencies\n";
  }
}
$dependencies_file->close();

$sections->{"Core"} = InstSection->new(
  "Core",
  $licenses->{"LGPL_2.1"},
  [],
  "Coq Core Component",
  "Coq Core Component",
  "Required",
  $groups->{"Core"}
);
$sections->{"Ssreflect"} = InstSection->new(
  "Ssreflect",
  $licenses->{"CeCILL_B"},
  [],
  "Ssreflect extension and its test suite of libraries",
  "This contribution includes an extension for the Coq system and a small set of libraries coming from the project of formalisation of the Feit-Thompson theorem.",
  "Selected",
  $groups->{"Ssreflect"}
);

foreach my $section_name (sort (keys %$sections)) {
  my $section = $sections->{$section_name};
  push(@{$section->group->sections}, $section);
  push(@{$section->license->sections}, $section);
  foreach my $dep_section (@{$section->dependencies}) {
    push(@{$dep_section->reverse_dependencies}, $section);
  }
}

## List Files ##

my $instfiles = [];

sub find_proc {
  my $abs_path = $File::Find::name;
  if($abs_path ne $coq_root) {
    my $rel_path = substr($File::Find::name, length($coq_root)+1, length($abs_path)-length($coq_root)-1);
    my $section_name = "Core";
    if($rel_path =~ m/^lib\/user-contrib-postload\/([^\/]+)/) {
      $section_name = $1;
    }
    if(exists $sections->{$section_name}) {
      push(@$instfiles, InstFile->new($sections->{$section_name}, "$coq_root/$rel_path", "$rel_path"));
    } else {
      # print("unknown: $section_name\n");
    }
  }
}
find(\&find_proc, $coq_root);

foreach my $section (values %$sections) {
  push(@$instfiles, InstFile->new($section, "$section->{'license'}->{'filename'}", "license_$section->{'name'}.txt"));
}

foreach my $instfile (@$instfiles) {
  push(@{$instfile->section->files}, $instfile);
}

## Classes ##

{
  package InstLicense;
  sub new {
    my $pkg = shift;
    my $hash = {
      name => shift,
      filename => shift,
      sections => [],
    };
    bless $hash,$pkg;
  }
  sub name     { return shift->{"name"    }; }
  sub filename { return shift->{"filename"}; }
  sub sections { return shift->{"sections"}; }
}

{
  package InstSectionGroup;
  sub new {
    my $pkg = shift;
    my $hash = {
      name => shift,
      title => shift,
      description => shift,
      instmode => shift,
      sections => []
    };
    bless $hash,$pkg;
  }
  sub name        { return shift->{"name"       }; }
  sub title       { return shift->{"title"      }; }
  sub description { return shift->{"description"}; }
  sub instmode    { return shift->{"instmode"   }; }
  sub sections    { return shift->{"sections"   }; }
}

{
  package InstSection;
  sub new {
    my $pkg = shift;
    my $hash = {
      name => shift,
      license => shift,
      dependencies => shift,
      title => shift,
      description => shift,
      instmode => shift,
      group => shift,
      files => [],
      reverse_dependencies => [],
    };
    bless $hash,$pkg;
  }
  sub name                 { return shift->{"name"                }; }
  sub license              { return shift->{"license"             }; }
  sub dependencies         { return shift->{"dependencies"        }; }
  sub reverse_dependencies { return shift->{"reverse_dependencies"}; }
  sub title                { return shift->{"title"               }; }
  sub description          { return shift->{"description"         }; }
  sub instmode             { return shift->{"instmode"            }; }
  sub group                { return shift->{"group"               }; }
  sub files                { return shift->{"files"               }; }
}

{
  package InstFile;
  sub new {
    my $pkg = shift;
    my $hash = {
      section => shift,
      srcfile => shift,
      dstfile => shift
    };
    bless $hash,$pkg;
  }
  sub section { return shift->{"section"}; }
  sub srcfile { return shift->{"srcfile"}; }
  sub dstfile { return shift->{"dstfile"}; }
}

## Auxiliary Subroutines ##

sub readDescription {
  my $name = shift;
  my $ret = {};
  my $descfile = IO::File->new("$wd/contrib-$coq_version/$name/description", 'r') or die $!;
  my $currentElem = "";
  foreach my $line (<$descfile>) {
    chomp $line;
    if($line =~ m/^(.*): (.*)$/) {
      $currentElem = $1;
      $ret->{$currentElem} = $2;
    } else {
      $ret->{$currentElem} .= " $line";
    }
  }
  $descfile->close();
  return $ret;
}

sub escapeNSIS {
  my $a = shift(@_);
  $a =~ s/\$/\$\$/g;
  $a =~ s/"/\$\\"/g;
  $a =~ s/\n/\$\\n/g;
  $a =~ s/\r/\$\\r/g;
  $a =~ s/\t/\$\\t/g;
  return $a;
}
sub escapeNSISFile {
  my $a = shift(@_);
  $a =~ s/\//\\/g;
  return escapeNSIS($a);
}

## Output ##

my $script_file = IO::File->new('installer.nsi', 'w') or die $!;
$script_file->print(<<"EOD");
OutFile "coq-unofficial-${coq_version}-win32.exe"
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

Name "Coq Unofficial Build ${coq_version}"
Icon "logo.ico"

InstallDirRegKey HKCU "Software\\Coq-Unofficial" ""

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "$licenses->{'LGPL_2.1'}->{'filename'}"
!insertmacro MUI_PAGE_COMPONENTS
EOD

foreach my $license (values %$licenses) {
  if($license->name eq "LGPL_2.1" || $license->name eq "PD") {
    next;
  }
  $script_file->print("; Begin: $license->{'name'}\n");
  $script_file->print("  !define MUI_PAGE_CUSTOMFUNCTION_PRE CustomPage_license_$license->{'name'}\n");
  $script_file->print("  !insertmacro MUI_PAGE_LICENSE \"$license->{'filename'}\"\n");
  $script_file->print("; End: $license->{'name'}\n");
  $script_file->print("\n");
}

$script_file->print(<<"EOD");
!insertmacro MULTIUSER_PAGE_INSTALLMODE
!insertmacro MUI_PAGE_DIRECTORY

!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\\Coq-Unofficial"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
!insertmacro MUI_PAGE_STARTMENU Application \$StartMenuFolder
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

EOD

foreach my $group (@$group_list) {
  my $use_group =
    ($group->instmode eq "Single"   && scalar(@{$group->sections}) >= 2) ||
    ($group->instmode eq "Multiple" && scalar(@{$group->sections}) >= 1);
  if($use_group) {
    $script_file->print("SectionGroup \"$group->{'title'}\" SectionGroup_$group->{'name'}\n");
  } else {
    $script_file->print("; SectionGroup \"$group->{'title'}\" SectionGroup_$group->{'name'}\n");
  }
  foreach my $section (@{$group->sections}) {
    if($section->instmode eq "Required" || $section->instmode eq "Selected") {
      $script_file->print("  Section \"$section->{'name'} - $section->{'title'}\" Section_$section->{'name'}\n");
    } else {
      $script_file->print("  Section /o \"$section->{'name'} - $section->{'title'}\" Section_$section->{'name'}\n");
    }
    if($section->instmode eq "Required") {
      $script_file->print("    SectionIn RO\n");
    }
    foreach my $instfile (@{$section->files}) {
      if(-d $instfile->srcfile) {
        $script_file->print("    CreateDirectory \$INSTDIR\\" . escapeNSISFile($instfile->dstfile) . "\n");
      } else {
        $script_file->print("    File     /oname=\$INSTDIR\\" . escapeNSISFile($instfile->dstfile) . " " . escapeNSISFile($instfile->{'srcfile'}) . "\n");
      }
    }
    if($section->name eq "Core") {
      $script_file->print(<<"EOD");
    WriteRegStr HKCU "Software\\Coq-Unofficial" "" \$INSTDIR
    WriteUninstaller "\$INSTDIR\\Uninstall.exe"

    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
      ;Create shortcuts
      CreateDirectory "\$SMPROGRAMS\\\$StartMenuFolder"
      CreateShortCut  "\$SMPROGRAMS\\\$StartMenuFolder\\CoqIDE.lnk"      "\$INSTDIR\\bin\\coqide.exe"
      CreateShortCut  "\$SMPROGRAMS\\\$StartMenuFolder\\Coq Console.lnk" "\$INSTDIR\\bin\\coqtop.exe"
      CreateShortCut  "\$SMPROGRAMS\\\$StartMenuFolder\\Uninstall.lnk"   "\$INSTDIR\\Uninstall.exe"
    !insertmacro MUI_STARTMENU_WRITE_END

    \${If} \$FileAssociationCheckboxState <> 0
      \${registerExtension} "\$INSTDIR\\bin\\coqide.exe" ".v" "Coq vernacular file"
    \${EndIf}
EOD
    }
    $script_file->print("  SectionEnd\n");
  }
  if($use_group) {
    $script_file->print("SectionGroupEnd\n");
  } else {
    $script_file->print("; SectionGroupEnd\n");
  }
  $script_file->print("\n");
}

$script_file->print("!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN\n");
foreach my $section (values %$sections) {
  $script_file->print("  !insertmacro MUI_DESCRIPTION_TEXT \${Section_$section->{'name'}} \"" . escapeNSIS($section->{'description'}) . "\"\n");
}
foreach my $group (@$group_list) {
  my $use_group =
    ($group->instmode eq "Single"   && scalar(@{$group->sections}) >= 2) ||
    ($group->instmode eq "Multiple" && scalar(@{$group->sections}) >= 1);
  if($use_group) {
    $script_file->print("  !insertmacro MUI_DESCRIPTION_TEXT \${SectionGroup_$group->{'name'}} \"" . escapeNSIS($group->{'description'}) . "\"\n");
  }
}
$script_file->print("!insertmacro MUI_FUNCTION_DESCRIPTION_END\n");
$script_file->print("\n");

$script_file->print("Section \"Uninstall\"\n");
foreach my $instfile (reverse @$instfiles) {
  if(-d $instfile->srcfile) {
    $script_file->print("  RmDir  \$INSTDIR\\" . escapeNSISFile($instfile->dstfile) . "\n");
  } else {
    $script_file->print("  Delete \$INSTDIR\\" . escapeNSISFile($instfile->dstfile) . "\n");
  }
}
$script_file->print(<<"EOD");
  !insertmacro MUI_STARTMENU_GETFOLDER Application \$StartMenuFolder
  Delete "\$SMPROGRAMS\\\$StartMenuFolder\\Coq Console.lnk"
  Delete "\$SMPROGRAMS\\\$StartMenuFolder\\CoqIDE.lnk"
  Delete "\$SMPROGRAMS\\\$StartMenuFolder\\Uninstall.lnk"
  RMDir  "\$SMPROGRAMS\\\$StartMenuFolder"

  \${unregisterExtension} ".v" "Coq vernacular file"

  # Always delete uninstaller as the last action
  Delete \$INSTDIR\\Uninstall.exe
  
  # Try to remove the install directory - this will only happen if it is empty
  RmDir \$INSTDIR

  # Remove uninstaller information from the registry
  DeleteRegKey /ifempty HKCU "Software\\Coq-Unofficial"
SectionEnd

Function PageAskingFileAssociation
  nsDialogs::Create 1018
  !insertmacro MUI_HEADER_TEXT "File Association" "Check if you want to associate *.v files to CoqIDE."
  \${NSD_CreateCheckbox} 80u 50u 100% 10u "Associate *.v files to CoqIDE"
  Pop \$FileAssociationCheckbox
  nsDialogs::Show
FunctionEnd

Function PageAskingFileAssociationLeave
  \${NSD_GetState} \$FileAssociationCheckbox \$FileAssociationCheckboxState
FunctionEnd

EOD

$script_file->print("Function .onSelChange\n");
foreach my $section (values %$sections) {
  if(scalar(@{$section->reverse_dependencies}) == 0) {
    next;
  }
  my $isfirst = 1;
  foreach my $rdep_section (@{$section->reverse_dependencies}) {
    if($isfirst) {
      $script_file->print("  \${If} \${SectionIsSelected} \${Section_$rdep_section->{'name'}}\n");
    } else {
      $script_file->print("  \${OrIf} \${SectionIsSelected} \${Section_$rdep_section->{'name'}}\n");
    }
    $isfirst = 0;
  }
  $script_file->print("    SectionGetFlags \${Section_$section->{'name'}} \$0\n");
  $script_file->print("    IntOp \$0 \$0 | \${SF_SELECTED}\n");
  $script_file->print("    SectionSetFlags \${Section_$section->{'name'}} \$0\n");
  $script_file->print("  \${EndIf}\n");
  $script_file->print("  \${IfNot} \${SectionIsSelected} \${Section_$section->{'name'}}\n");
  foreach my $rdep_section (@{$section->reverse_dependencies}) {
    $script_file->print("    SectionGetFlags \${Section_$rdep_section->{'name'}} \$0\n");
    $script_file->print("    IntOp \$0 \$0 | \${SF_SELECTED}\n");
    $script_file->print("    IntOp \$0 \$0 ^ \${SF_SELECTED}\n");
    $script_file->print("    SectionSetFlags \${Section_$rdep_section->{'name'}} \$0\n");
  }
  $script_file->print("  \${EndIf}\n");
  $script_file->print("\n");
}
$script_file->print("FunctionEnd\n");
$script_file->print("\n");

foreach my $license (values %$licenses) {
  if($license->name eq "LGPL_2.1" || $license->name eq "PD") {
    next;
  }
  $script_file->print("Function CustomPage_license_$license->{'name'}\n");
  my $isfirst = 1;
  foreach my $section (@{$license->sections}) {
    if($isfirst) {
      $script_file->print("  \${IfNot} \${SectionIsSelected} \${Section_$section->{'name'}}\n");
    } else {
      $script_file->print("  \${AndIfNot} \${SectionIsSelected} \${Section_$section->{'name'}}\n");
    }
    $isfirst = 0;
  }
  $script_file->print("  Abort\n");
  $script_file->print("  \${EndIf}\n");
  $script_file->print("FunctionEnd\n");
  $script_file->print("\n");
}

$script_file->close();
