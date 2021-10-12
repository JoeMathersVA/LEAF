<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

require '../db_mysql.php';
require '../sources/CDW.php';

if (!class_exists('XSSHelpers'))
{
    include_once dirname(__FILE__) . '/../../../libs/php-commons/XSSHelpers.php';
}

/**
 * Purpose: Class to connect to VA's CDW databases (MSSQL)
 */
class CDWdataController extends RESTfulResponse
{
    public $index = array();

    private $API_VERSION = 1;    // Integer

    private $cdw;

    private $db;

    //private $CDW_db;

    private $login;

    public function __construct($db, $login)
    {
        $this->login = $login;
        $this->cdw = new CDW($db, $login);
    }

    public function verifyVaccineReferrer() {
        return ($this->verifyAdminReferrer() && strpos($_SERVER['REQUEST_URI'], 'NATIONAL/101/vaccine_data_reporting') !== 'false');
    }

    public function get($act)
    {
        $cdw = $this->cdw;

        $this->index['GET'] = new ControllerMap();
        $cm = $this->index['GET'];
        $cm->register('cdw/version', function () {
            return $this->API_VERSION;
        });

        return $cm->runControl($act['key'], $act['args']);
    }

    public function post($act)
    {
        $cdw = $this->cdw;

        //$this->verifyVaccineReferrer();

        $this->index['POST'] = new ControllerMap();
        $cm = $this->index['POST'];
        $cm->register('cdw', function ($args) {
        });

        /** Validate Vaccine Status in CDW - Expects Valid Email Address and Optional Pathway*/
        $cm->register('cdw/vaccine/status', function () use ($cdw) {
            return $cdw->getVaccineStatus();
        });

        /** Modify Vaccine when record ID unknown **/
        $cm->register('cdw/vaccine/submit', function ($args) use ($cdw) {
            return $cdw->modifyVaccine();
        });

        /** Modify Vaccine - Expects Record ID number */
        $cm->register('cdw/vaccine/[digit]/submit', function ($args) use ($cdw) {
            return $cdw->modifyVaccine(XSSHelpers::xscrub($args[0]));
        });

        return $this->index['POST']->runControl($act['key'], $act['args']);
    }

    public function delete($act)
    {
        $db = $this->db;
        $login = $this->login;
        $cdw = $this->cdw;

        //$this->verifyVaccineReferrer();

        $this->index['DELETE'] = new ControllerMap();
        $this->index['DELETE']->register('cdw', function ($args) {
        });

        // Expected digit is LEAF Record ID to be removed from CDW Uploads
        $this->index['DELETE']->register('cdw/[digit]/remove', function ($args) use ($cdw) {
            return $cdw->deleteVaccine(XSSHelpers::xscrub($args[0]));
        });

        return $this->index['DELETE']->runControl($act['key'], $act['args']);
    }
}
