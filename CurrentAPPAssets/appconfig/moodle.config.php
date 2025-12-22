<?php
$CFG = new stdClass();

$CFG->dbtype    = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = getenv('MOODLE_DB_HOST');
$CFG->dbname    = getenv('MOODLE_DB_NAME');
$CFG->dbuser    = getenv('MOODLE_DB_USER');
$CFG->dbpass    = getenv('MOODLE_DB_PASS');
$CFG->prefix    = 'mdl_';

$CFG->wwwroot   = getenv('MOODLE_URL');
$CFG->dataroot  = getenv('MOODLE_DATA_PATH');

$CFG->directorypermissions = 0777;

require_once(__DIR__ . '/lib/setup.php');
