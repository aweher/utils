#!/usr/bin/perl
# Script que realiza el backup de las bases de datos de MySQL
# Hecho por Ariel S. Weher para ClearUpIT
use strict;
use warnings;
use DBI;

# Defino los parametros de la base de datos a la que me voy a conectar
my $host = 'localhost';
my $usuario = 'root';
my $password = `cat /root/.my.cnf | grep password | cut -d '=' -f 2`;
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
my $parametros = "-h$host -u$usuario -p$password --flush-logs --opt --single-transaction --hex-blob";

# Obtengo todas las bases del server

my @bases = ();
my @lineas = `$mysqlprogram -h $host -u$usuario -p$password -e "show databases" --batch`;

my $n = 0;
foreach (@lineas){
        $n++;
        chomp;
        next if ($_ =~ /information_schema/);
        next if ($_ =~ /performance_schema/);
        push(@bases, $_) unless $n eq 1;
}

# Obtengo la fecha en este formato: 20070606-120645
my $fechahora = `$dateprogram +%Y%m%d-%H%M%S%s`;
chomp $fechahora;

my $directorio = $dirdestino.$fechahora.'.borrame/';
my $existeeldir = 0;

# Extraigo las bases...
foreach my $base (@bases){
        print "Making Backup of Base: $base ($fechahora)...\n";

        # Creo el directorio si es que no existe...
        if (!$existeeldir){
                my $tmpcmd = `$mkdirprogram $directorio`;
                $existeeldir = 1;
        }
        my $tmparchivo = $directorio.$base.'.sql';
        my $tmpcmd = `$dumpprogram $parametros $base > $tmparchivo`;
        $fechahora = `/bin/date +%Y%m%d-%H%M%S-%s`;
        chomp $fechahora;
}

# Comprimo el archivo usando bzip2
print "Compressing temp dir ($directorio)\n";

$fechahora = `$dateprogram +%Y%m%d-%H%M%S-%s`;
chomp $fechahora;

# Voy a ver cuantos archivos hay en el directorio...
my $cantarchivos = `$lsprogram -t -r -1 $dirdestino | $wcprogram -l`;
chomp $cantarchivos;

if ($cantarchivos > $numbackup){
        # Obtengo el archivo mas viejo del directorio
        my $archivomasviejo = `$lsprogram -t -r -1 $dirdestino | $headprogram -1`;
        chomp $archivomasviejo;
        my $jobh = `$rmprogram -rf $archivomasviejo`;
}

my $archivodestino = $dirdestino."bases.$fechahora.tar.bz2";
chomp $archivodestino;

my $tmpcmd = `$tarprogram cvfj $archivodestino $directorio`;
print "\nI have created the file $archivodestino\n";
print "Cleaning temp dirs...\n";
$tmpcmd = `$rmprogram -rf $directorio` if ($directorio =~ /.*borrame.*/);
$tmpcmd = `$rmprogram -rf $dirdestino$linksimbolico`;
$tmpcmd = `$lnprogram -s $archivodestino "$dirdestino$linksimbolico"`;
print"Have a nice day...\n";

exit 0;
