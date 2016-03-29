#!/usr/bin/perl
# Script que realiza el backup de las bases de datos de MySQL
# Hecho por Ariel S. Weher
use strict;
use warnings;
use DBI;
use Getopt::Long;

# Opciones
my $READONLY = "";
my $DEBUG = "";
my $N = "";
my $v = "";

# Leo los parametros que me pasaron desde la shell
GetOptions(
        "N!"=>\$READONLY,
        "v!"=>\$DEBUG,
);

print "USANDO MODO DEBUG\n" if $DEBUG;
print "USANDO MODO SOLO LECTURA, NO SE ESCRIBIRAN ARCHIVOS\n" if $READONLY;

# Defino los parametros de la base de datos a la que me voy a conectar
my $host = 'localhost';
my $usuario = `whoami`;
my $password = `cat ~/.my.cnf | grep password | cut -d '=' -f 2`;
my $dirdestino = '/srv/backups/mysql/';

# Cuantos archivos de backup voy a mantener? (sumar uno por el link simbolico)
my $numbackup = 365;
# Nombre del link simbolico
my $linksimbolico = "latest-mysql-backup.tar.bz2";

# Path de los programas a usar
my $mysqlprogram = '/usr/bin/mysql';
my $dumpprogram = "/usr/bin/mysqldump";
my $tarprogram = '/bin/tar';
my $rmprogram = '/bin/rm';
my $lsprogram = '/bin/ls';
my $dateprogram = '/bin/date';
my $mkdirprogram = '/bin/mkdir';
my $headprogram = '/usr/bin/head';
my $wcprogram = '/usr/bin/wc';
my $lnprogram = '/bin/ln';
my $cpprogram = '/bin/cp';

chomp $password;

# Defino el programa que voy a usar para obtener la copia de la base de datos y sus parametros de funcionamiento
my $parametros = "-h$host -u$usuario -p$password --flush-logs --opt --add-drop-database --hex-blob --routines --triggers --events --single-transaction";

# Obtengo todas las bases del server

my @bases = ();
my @lineas = `$mysqlprogram -h $host -u$usuario -p$password -e "SHOW DATABASES" --batch`;

my $n = 0;
foreach (@lineas){
        $n++;
        chomp;
        next if ($_ =~ /information_schema/);
        next if ($_ =~ /performance_schema/);
        print "Encontre la base: $_\n" if $DEBUG;
        push(@bases, $_) unless $n eq 1;
}

# Obtengo la fecha en este formato: 20070606-120645
my $fechahora = `$dateprogram +%Y%m%d-%H%M%S%s`;
chomp $fechahora;
print "La variable \$fechahora es: $fechahora\n" if $DEBUG;

my $directorio = $dirdestino.$fechahora.'.borrame/';
my $existeeldir = 0;

##### Parche para ocupar menos espacio..
#@bases = ();
#@bases = qw /database1 database2 database5/;

# Extraigo las bases...
foreach my $base (@bases){
        print "Making Backup of Base: $base ($fechahora)...\n if $DEBUG";

        # Creo el directorio si es que no existe...
        if (!$existeeldir){
                my $tmpcmd = `$mkdirprogram $directorio` if not $READONLY;
                $existeeldir = 1;
        }
        my $tmparchivo = $directorio.$base.'.sql';
        my $tmpcmd = `$dumpprogram $parametros $base > $tmparchivo` if not $READONLY;
        $fechahora = `/bin/date +%Y%m%d-%H%M%S-%s`;
        chomp $fechahora;
}

# Comprimo el archivo usando bzip2
print "Compressing temp dir ($directorio)\n" if $DEBUG;

$fechahora = `$dateprogram +%Y%m%d-%H%M%S-%s`;
chomp $fechahora;

# Voy a ver cuantos archivos hay en el directorio...
my $cantarchivos = `$lsprogram -t -r -1 $dirdestino | $wcprogram -l`;
chomp $cantarchivos;

if ($cantarchivos > $numbackup){
        # Obtengo el archivo mas viejo del directorio
        my $archivomasviejo = `$lsprogram -t -r -1 $dirdestino | $headprogram -1`;
        chomp $archivomasviejo;
        my $jobh = `$rmprogram -rf $archivomasviejo` if not $READONLY;
}

my $archivodestino = $dirdestino."bases.$fechahora.tar.bz2";
chomp $archivodestino;

my $tmpcmd = `$tarprogram cvfj $archivodestino $directorio`;
print "\nI have created the file $archivodestino\n" if $DEBUG;
print "Cleaning temp dirs...\n" if $DEBUG;
$tmpcmd = `$rmprogram -rf $directorio` if ($directorio =~ /.*borrame.*/);
$tmpcmd = `$rmprogram -rf $dirdestino$linksimbolico` if not $READONLY;
$tmpcmd = `$lnprogram -s $archivodestino "$dirdestino$linksimbolico"` if not $READONLY;
print"Have a nice day...\n" if $DEBUG;

exit 0;
