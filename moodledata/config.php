<?php
$CFG = new stdClass();

$CFG->dbtype    = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'db_moodle_dev';
$CFG->dbname    = 'db_moodle_dev';
$CFG->dbuser    = 'dbuser';
$CFG->dbpass    = '1234';
$CFG->prefix    = 'mdl_';

$CFG->wwwroot   = 'moodle.localhost';
$CFG->dataroot  = '/var/moodledata';

$CFG->directorypermissions = 0777;

require_once(__DIR__ . '/lib/setup.php');

